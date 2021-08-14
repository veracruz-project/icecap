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
use icecap_host_vmm_config::*;
use icecap_vmm::*;
use icecap_event_server_types as event_server;
use icecap_resource_server_types as resource_server;

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {
    // let con = BufferedRingBuffer::new(RingBuffer::realize_resume_unmanaged(&config.con));
    // icecap_std::set_print(con);

    let resource_server_ep = config.resource_server_ep;
    let event_server_client_ep = config.event_server_client_ep;
    let event_server_control_ep = config.event_server_control_ep;

    let irq_map = IRQMap {
        ppi: config.ppi_map.into_iter().map(|(ppi, in_index)| (ppi, in_index.to_nat())).collect(),
        spi: config.spi_map.into_iter().map(|(spi, (in_index, nid))| (spi, (in_index.to_nat(), nid))).collect(),
    };

    VMMConfig {
        debug: false,
        cnode: config.cnode,
        gic_lock: config.gic_lock,
        nodes_lock: config.nodes_lock,
        event_server_client_ep,
        irq_map,
        gic_dist_paddr: config.gic_dist_paddr,
        kicks: config.kicks.iter().map(|kick_config| {
            match kick_config {
                KickConfig::Notification(nfn) => {
                    let nfn = *nfn;
                    Box::new(move |node: &VMMNode<Extension>| {
                        Ok(nfn.signal())
                    }) as Box<dyn for<'r> Fn(&'r VMMNode<Extension>) -> Fallible<()> + Send + Sync>
                }
                KickConfig::OutIndex(index) => {
                    let index = index.clone();
                    Box::new(move |node: &VMMNode<Extension>| {
                        Ok(node.event_server_client.call::<()>(&event_server::calls::Client::Signal {
                            index: index.to_nat(),
                        }))
                    })
                }
            }
        }).collect(),
        nodes: config.nodes.iter().enumerate().map(|(i, node)| {
            VMMNodeConfig {
                tcb: node.tcb,
                vcpu: node.vcpu,
                ep: node.ep_read,
                fault_reply_slot: node.fault_reply_slot,
                thread: node.thread,
                extension: Extension {
                    resource_server_ep: resource_server_ep[i],
                    event_server_control_ep: event_server_control_ep[i],
                },
            }
        }).collect(),
    }.run()
}

struct Extension {
    resource_server_ep: Endpoint,
    event_server_control_ep: Endpoint,
}

const SYS_RESOURCE_SERVER_PASSTHRU: Word = 1338;
const SYS_YIELD_TO: Word = 1339;

impl VMMExtension for Extension {

    fn handle_wfe(node: &mut VMMNode<Self>) -> Fallible<()> {
        panic!("wfe");
        Ok(())
    }

    fn handle_syscall(node: &mut VMMNode<Self>, syscall: u64) -> Fallible<()> {
        match syscall {
            SYS_RESOURCE_SERVER_PASSTHRU => {
                Self::sys_resource_server_passthru(node)?;
            }
            SYS_YIELD_TO => {
                Self::sys_yield_to(node)?;
            }
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

    fn sys_resource_server_passthru(node: &mut VMMNode<Self>) -> Fallible<()> {
        let mut ctx = node.tcb.read_all_registers(false)?;
        let length = ctx.x0 as usize;
        let parameters = &[ctx.x1, ctx.x2, ctx.x3, ctx.x4, ctx.x5, ctx.x6][..length];
        let recv_info = node.extension.resource_server_ep.call(proxy::up(parameters));
        let mut r = proxy::down(&recv_info);
        assert!(r.len() <= 6);
        ctx.x0 = r.len() as u64;
        r.resize_with(6, || 0);
        ctx.x1 = r[0];
        ctx.x2 = r[1];
        ctx.x3 = r[2];
        ctx.x4 = r[3];
        ctx.x5 = r[4];
        ctx.x6 = r[5];
        ctx.pc += 4;
        node.tcb.write_all_registers(false, &mut ctx)?;
        Ok(())
    }

    fn sys_yield_to(node: &mut VMMNode<Self>) -> Fallible<()> {
        let bound = node.upper_ns_bound_interrupt()?;
        let mut ctx = node.tcb.read_all_registers(false)?;
        let realm_id = ctx.x0 as usize;
        let virtual_node = ctx.x1 as usize;
        let resp = RPCClient::new(node.extension.resource_server_ep).call::<resource_server::ResumeHostCondition>(&resource_server::Request::YieldTo {
            physical_node: node.node_index,
            realm_id,
            virtual_node,
            timeout: {
                let bound = bound.unwrap();
                if bound < 0 { None } else { Some(bound as usize) }
            }
        });
        ctx.pc += 4;
        node.tcb.write_all_registers(false, &mut ctx)?;
        Ok(())
    }
}
