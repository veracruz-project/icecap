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
use icecap_std::finite_set::Finite;
use icecap_rpc_sel4::*;
use icecap_realm_vmm_config::*;
use icecap_vmm::*;
use icecap_event_server_types as event_server;

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {
    // let con = BufferedRingBuffer::new(RingBuffer::realize_resume_unmanaged(&config.con));
    // icecap_std::set_print(con);

    let event_server_client_ep = config.event_server_client_ep;

    let irq_map = IRQMap {
        ppi: config.ppi_map.into_iter().map(|(ppi, (in_index, must_ack))| (ppi, (in_index.to_nat(), must_ack))).collect(),
        spi: config.spi_map.into_iter().map(|(spi, (in_index, nid, must_ack))| (spi, (in_index.to_nat(), nid, must_ack))).collect(),
    };

    VMMConfig {
        debug: true,
        cnode: config.cnode,
        gic_lock: config.gic_lock,
        nodes_lock: config.nodes_lock,
        event_server_client_ep,
        irq_map,
        gic_dist_paddr: config.gic_dist_paddr,
        nodes: config.nodes.iter().map(|node| {
            VMMNodeConfig {
                tcb: node.tcb,
                vcpu: node.vcpu,
                ep: node.ep_read,
                fault_reply_slot: node.fault_reply_slot,
                event_server_bitfield: node.event_server_bitfield,
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
