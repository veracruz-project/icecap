#![no_std]
#![no_main]
#![feature(format_args_nl)]

extern crate alloc;

use core::convert::TryFrom;
use core::sync::atomic::{AtomicBool, Ordering};

use alloc::collections::btree_map::BTreeMap;
use alloc::sync::Arc;

use biterate::biterate;

use icecap_std::prelude::*;
use icecap_host_vmm_config::*;
use icecap_vmm::*;

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {
    let con_rb = RingBuffer::realize_resume(&config.con);
    let con = BufferedRingBuffer::new(con_rb);
    // icecap_std::set_print(con); // TODO

    // Endpoints used to synchronously alert the vmm thread of an Event
    let ep_writes: Vec<Endpoint> = config.nodes.iter().map(|node| node.ep_write).collect();
    let ep_writes = Arc::new(ep_writes);

    for group in config.virtual_irqs {
        let nfn = group.nfn;
        let irq_vals: Vec<Option<IRQ>> = group.irqs.clone();
        group.thread.start({
            let irq_vals: Vec<Option<IRQ>> = group.irqs.clone();
            let ep_writes = Arc::clone(&ep_writes);
            move || {
                loop {
                    let badge = nfn.wait();
                    for i in biterate(badge) {
                        let node = 0;
                        let spi = irq_vals[i as usize].unwrap();
                        MR_0.set(spi as u64);
                        ep_writes[node].send(MessageInfo::new(0, 0, 0, 1)); // HACK
                    }
                }
            }
        })
    }

    let mut irq_handlers = BTreeMap::new();

    for group in config.passthru_irqs {
        let nfn = group.nfn;
        for irq in &group.irqs {
            if let Some(irq) = irq {
                irq.handler.ack().unwrap(); // TODO is this correct and necessary
                irq_handlers.insert(irq.irq, irq.handler);
            }
        }
        let irq_vals: Vec<Option<IRQ>> = group.irqs.iter().map(|irq| irq.as_ref().map(|x| x.irq)).collect();
        group.thread.start({
            let irq_vals: Vec<Option<IRQ>> = group.irqs.iter().map(|irq| irq.as_ref().map(|x| x.irq)).collect();
            let ep_writes = Arc::clone(&ep_writes);
            move || {
                loop {
                    let badge = nfn.wait();
                    for i in biterate(badge) {
                        let node = 0;
                        let spi = irq_vals[i as usize].unwrap();
                        MR_0.set(spi as u64);
                        ep_writes[node].send(MessageInfo::new(0, 0, 0, 1)); // HACK
                    }
                }
            }
        })
    }

    let vmm_config = VMMConfig {
        cnode: config.cnode,
        gic_dist_paddr: config.gic_dist_paddr,
        gic_lock: Notification::from_raw(0),
        nodes_lock: Notification::from_raw(0),
        irq_handlers: irq_handlers,
        nodes: config.nodes.iter().map(|node| {
            VMMNodeConfig {
                tcb: node.tcb,
                vcpu: node.vcpu,
                ep: node.ep_read,
                fault_reply_slot: node.reply_ep,
                thread: node.thread,
                extension: Extension {

                },
            }
        }).collect(),
    };

    vmm_config.run()
}

struct Extension {

}

impl VMMExtension for Extension {

    fn handle_wfe(node: &mut VMMNode<Self>) -> Fallible<()> {
        panic!("wfi");
        Ok(())
    }

    fn handle_syscall(node: &mut VMMNode<Self>, syscall: u64) -> Fallible<()> {
        panic!("unknown syscall");
        Ok(())
    }

    fn handle_putchar(node: &mut VMMNode<Self>, c: u8) -> Fallible<()> {
        debug_print!("{}", c as char);
        Ok(())
    }
}
