#![no_std]
#![no_main]
#![feature(format_args_nl)]
#![allow(unused_variables)]
#![allow(unused_imports)]
#![allow(unreachable_code)]

extern crate alloc;

use core::convert::TryFrom;
use core::sync::atomic::{AtomicBool, Ordering};
use alloc::collections::btree_map::BTreeMap;
use alloc::sync::Arc;

use biterate::biterate;

use icecap_std::prelude::*;
use icecap_rpc_sel4::*;
use icecap_realm_vmm_config::*;
use icecap_vmm::*;

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {
    let con = BufferedRingBuffer::new(RingBuffer::realize_resume(&config.con));
    // icecap_std::set_print(con);

    let ep_writes: Arc<Vec<Endpoint>> = Arc::new(config.nodes.iter().map(|node| node.ep_write).collect());

    let irq_handlers = BTreeMap::new();

    for group in config.virtual_irqs {
        group.thread.start({
            let nfn = group.nfn;
            let bits = group.bits.clone();
            let ep_writes = Arc::clone(&ep_writes);
            move || {
                loop {
                    let badge = nfn.wait();
                    for i in biterate(badge) {
                        let node = 0; // TODO
                        let spi = bits[i as usize].unwrap();
                        RPCClient::<usize>::new(ep_writes[node]).call::<()>(&spi);
                    }
                }
            }
        })
    }

    VMMConfig {
        cnode: config.cnode,
        gic_lock: config.gic_lock,
        nodes_lock: config.nodes_lock,
        irq_handlers: irq_handlers,
        gic_dist_paddr: config.gic_dist_paddr,
        nodes: config.nodes.iter().map(|node| {
            VMMNodeConfig {
                tcb: node.tcb,
                vcpu: node.vcpu,
                ep: node.ep_read,
                fault_reply_slot: node.fault_reply_slot,
                thread: node.thread,
                extension: Extension {
                },
            }
        }).collect(),
    }.run()
}

struct Extension {
}

impl VMMExtension for Extension {

    fn handle_wfe(node: &mut VMMNode<Self>) -> Fallible<()> {
        panic!("wfe");
        Ok(())
    }

    fn handle_syscall(node: &mut VMMNode<Self>, syscall: u64) -> Fallible<()> {
        match syscall {
            _ => {
                panic!("unknown syscall");
            }
        }
        Ok(())
    }

    fn handle_putchar(node: &mut VMMNode<Self>, c: u8) -> Fallible<()> {
        debug_print!("{}", c as char);
        Ok(())
    }
}

impl Extension {
}
