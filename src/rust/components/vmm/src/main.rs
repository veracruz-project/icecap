#![no_std]
#![no_main]
#![feature(format_args_nl)]

extern crate alloc;

use core::convert::TryFrom;
use core::sync::atomic::{AtomicBool, Ordering};

use alloc::collections::btree_map::BTreeMap;
use alloc::sync::Arc;

use icecap_std::prelude::*;
use icecap_vmm_config::Config;
use icecap_vmm_core::{
    run, Mailbox, IRQType, Event, biterate, Distributor, IRQ,
};

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {

    let con_rb = RingBuffer::realize_resume(&config.con);
    let con = BufferedRingBuffer::new(con_rb);
    // icecap_std::set_print(con); // TODO

    // Endpoints used to synchronously alert the vmm thread of an Event
    let ep_writes: Vec<Endpoint> = config.nodes.iter().map(|node| node.ep_write).collect();
    let ep_writes = Arc::new(ep_writes);

    // Notifications and mailboxes used to asynchronously inform a vmm thread of an Event
    let nfn_writes: Vec<Notification> = config.nodes.iter().map(|node| node.nfn_write).collect();
    let nfn_writes = Arc::new(nfn_writes);

    let mailboxes: Vec<Mailbox> = config.nodes.iter().map(|_| Mailbox::new()).collect();
    let mailboxes = Arc::new(mailboxes);

    // Create the GIC distributor and reset it.
    // Wrap the gic_dist in an Arc to support sharing amongst vmm threads.
    let gic_dist = Arc::new(Distributor::new(config.nodes.len()));

    let mut irqs = BTreeMap::new();
    irqs.insert(config.virtual_timer_irq, IRQType::Timer);

    // Register all SGIs (IRQs 0 to 15)
    for irq in 0..16 {
        irqs.insert(irq, IRQType::SGI);
    }

    for group in config.virtual_irqs {
        let nfn = group.nfn;
        for irq in &group.irqs {
            if let Some(irq) = irq {
                irqs.insert(*irq, IRQType::Virtual);
            }
        }
        let irq_vals: Vec<Option<IRQ>> = group.irqs.clone();
        group.thread.start({
            let irq_vals: Vec<Option<IRQ>> = group.irqs.clone();
            let gic_dist = Arc::clone(&gic_dist);
            let ep_writes = Arc::clone(&ep_writes);
            move || {
                loop {
                    let badge = nfn.wait();
                    for i in biterate(badge) {
                        let nodes = gic_dist.get_vcpu_targets(irq_vals[i as usize].unwrap());
                        for node in nodes {
                            Event::SPI(irq_vals[i as usize].unwrap()).send(ep_writes[node]);
                        }
                    }
                }
            }
        })
    }

    for group in config.passthru_irqs {
        let nfn = group.nfn;
        for irq in &group.irqs {
            if let Some(irq) = irq {
                irq.handler.ack().unwrap(); // TODO is this correct and necessary
                irqs.insert(irq.irq, IRQType::Passthru(irq.handler));
            }
        }
        let irq_vals: Vec<Option<IRQ>> = group.irqs.iter().map(|irq| irq.as_ref().map(|x| x.irq)).collect();
        group.thread.start({
            let irq_vals: Vec<Option<IRQ>> = group.irqs.iter().map(|irq| irq.as_ref().map(|x| x.irq)).collect();
            let gic_dist = Arc::clone(&gic_dist);
            let ep_writes = Arc::clone(&ep_writes);
            move || {
                loop {
                    let badge = nfn.wait();
                    for i in biterate(badge) {
                        let nodes = gic_dist.get_vcpu_targets(irq_vals[i as usize].unwrap());
                        for node in nodes {
                            Event::SPI(irq_vals[i as usize].unwrap()).send(ep_writes[node]);
                        }
                    }
                }
            }
        })
    }

    // Funnel thread for each node to wait on notifications of an IRQ or Ack
    // being forwarded from another node.  The funnel thread checks the mailbox
    // for it's node to see which IRQ or Ack it needs to respond to, then
    // invokes the endpoint for it's node with the appropriate action.
    for (node_index, node) in config.nodes.iter().enumerate() {
        node.nfn_thread.start({
            let nfn_read = node.nfn_read;
            let ep_write = node.ep_write;
            let mailboxes = Arc::clone(&mailboxes);
            move || {
                let mailbox = &mailboxes[node_index];

                loop {
                    nfn_read.wait();

                    // loop through mailbox irqs
                    for irq in 0..mailbox.irq.len() {
                        let prev = mailbox.irq[irq].swap(false, Ordering::SeqCst);
                        if prev {
                            if irq < 16 {
                                Event::SGI(irq).send(ep_write);
                            } else if irq < 32 {
                                panic!("PPIs should never require forwarding from one core to another");
                            } else {
                                Event::SPI(irq).send(ep_write);
                            }
                        }
                    }
                }
            }
        })
    }

    let irqs = Arc::new(irqs);
    let start_eps = Arc::new(config.nodes.iter().skip(1).map(|node| node.start_ep).collect::<Vec<Endpoint>>());

    for (node_index, node) in config.nodes.iter().enumerate().skip(1) {
        node.thread.start({
            let tcb = node.tcb;
            let vcpu = node.vcpu;
            let gic_dist_paddr = config.gic_dist_paddr;
            let real_virtual_timer_irq = config.real_virtual_timer_irq;
            let virtual_timer_irq = config.virtual_timer_irq;

            let cspace = config.cnode;
            let fault_reply_ep = node.reply_ep;
            let ep_read = node.ep_read;

            let gic_dist = Arc::clone(&gic_dist);
            let irqs = Arc::clone(&irqs);
            let start_eps = Arc::clone(&start_eps);

            let nfn_writes = Arc::clone(&nfn_writes);
            let mailboxes = Arc::clone(&mailboxes);

            move || {
                run(
                    node_index,
                    tcb, vcpu, cspace, fault_reply_ep,
                    &gic_dist, gic_dist_paddr, // TODO rename in run args
                    &irqs, real_virtual_timer_irq, virtual_timer_irq,
                    ep_read, &start_eps, &nfn_writes, &mailboxes,
                    |c| print!("{}", c as char),
                    None,
                ).unwrap()
            }
        });
    }

    let node = &config.nodes[0];

    run(
        0,
        node.tcb, node.vcpu, config.cnode, node.reply_ep,
        &gic_dist, config.gic_dist_paddr, // TODO rename in run args
        &irqs, config.real_virtual_timer_irq, config.virtual_timer_irq,
        node.ep_read, &start_eps, &nfn_writes, &mailboxes,
        |c| print!("{}", c as char),
        None,
    )
}
