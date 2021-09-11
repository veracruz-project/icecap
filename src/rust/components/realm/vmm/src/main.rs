#![no_std]
#![no_main]
#![feature(format_args_nl)]

extern crate alloc;

use icecap_std::prelude::*;
use icecap_std::sel4::fault::*;
use icecap_std::finite_set::Finite;
use icecap_realm_vmm_config::*;
use icecap_vmm::*;

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {

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

    fn handle_wf(_node: &mut VMMNode<Self>) -> Fallible<()> {
        panic!()
    }

    fn handle_syscall(_node: &mut VMMNode<Self>, fault: &UnknownSyscall) -> Fallible<()> {
        #[allow(unreachable_code)]
        Ok(match fault.syscall {
            _ => {
                panic!("unknown syscall")
            }
        })
    }

    fn handle_putchar(_node: &mut VMMNode<Self>, c: u8) -> Fallible<()> {
        debug_print!("{}", c as char);
        Ok(())
    }
}
