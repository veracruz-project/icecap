#![no_std]
#![no_main]
#![feature(format_args_nl)]

extern crate alloc;

use alloc::collections::btree_map::BTreeMap;

use icecap_std::prelude::*;
use icecap_std::base_config_realize::*;
use icecap_vmm_config::Config;
use icecap_vmm_core::{
    run, IRQType, Event, biterate, IRQ,
};

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {

    let timer = realize_timer_client(&config.timer);
    let con_rb = realize_mapped_ring_buffer(&config.con);
    let con = ConDriver::new(con_rb);
    icecap_std::set_print(con);

    let ep_read = config.ep_read;
    let ep_write = config.ep_write;

    let cspace = config.cnode;
    let fault_reply_ep = config.reply_ep;

    let mut irqs = BTreeMap::new();
    irqs.insert(config.virtual_timer_irq, IRQType::Timer);

    for group in config.virtual_irqs {
        let nfn = group.nfn;
        for irq in &group.irqs {
            if let Some(irq) = irq {
                irqs.insert(*irq, IRQType::Virtual);
            }
        }
        let irq_vals: Vec<Option<IRQ>> = group.irqs.clone();
        group.thread.start(move || {
            loop {
                let badge = nfn.wait();
                for i in biterate(badge) {
                    Event::IRQ(irq_vals[i as usize].unwrap()).send(ep_write);
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
        group.thread.start(move || {
            loop {
                let badge = nfn.wait();
                for i in biterate(badge) {
                    Event::IRQ(irq_vals[i as usize].unwrap()).send(ep_write);
                }
            }
        })
    }

    let timer_wait = config.timer.wait;
    config.timer_thread.start(move || {
        loop {
            timer_wait.wait();
            Event::Timeout.send(ep_write);
        }
    });

    run(
        config.tcb, config.vcpu, cspace, fault_reply_ep, timer,
        config.gic_dist_vaddr, config.gic_dist_paddr, // TODO rename in run args
        irqs, config.real_virtual_timer_irq, config.virtual_timer_irq,
        ep_read,
        config.caput_ep_write.unwrap(),
        |c| print!("{}", c as char),
    )
}
