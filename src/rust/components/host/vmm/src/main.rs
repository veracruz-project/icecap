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
use icecap_benchmark_server_types as benchmark_server;
use icecap_host_vmm_types::{sys_id, DirectRequest, DirectResponse};

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {
    // let con = BufferedRingBuffer::new(RingBuffer::realize_resume_unmanaged(&config.con));
    // icecap_std::set_print(con);

    let resource_server_ep = config.resource_server_ep;
    let event_server_client_ep = config.event_server_client_ep;
    let event_server_control_ep = config.event_server_control_ep;
    let benchmark_server_ep = config.benchmark_server_ep;

    let irq_map = IRQMap {
        ppi: config.ppi_map.into_iter().map(|(ppi, in_index)| (ppi, in_index.to_nat())).collect(),
        spi: config.spi_map.into_iter().map(|(spi, (in_index, nid))| (spi, (in_index.to_nat(), nid))).collect(),
    };

    #[cfg(feature = "benchmark")]
    {
        // sel4::benchmark::set_log_buffer(config.log_buffer)?;
    }

    VMMConfig {
        debug: false,
        cnode: config.cnode,
        gic_lock: config.gic_lock,
        nodes_lock: config.nodes_lock,
        event_server_client_ep,
        irq_map,
        gic_dist_paddr: config.gic_dist_paddr,
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
                    benchmark_server_ep,
                },
            }
        }).collect(),
    }.run()
}

struct Extension {
    resource_server_ep: Endpoint,
    event_server_control_ep: Endpoint,
    benchmark_server_ep: Endpoint,
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
            sys_id::RESOURCE_SERVER_PASSTHRU => {
                Self::sys_resource_server_passthru(node)?;
            }
            sys_id::YIELD_TO => {
                Self::sys_yield_to(node)?;
            }
            sys_id::DIRECT => {
                Self::sys_direct(node)?;
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
        let bound = node.upper_ns_bound_interrupt()?.unwrap();
        // HACK this shouldn't be happening so often
        if bound <= 0 {
            return Ok(())
        }
        let mut ctx = node.tcb.read_all_registers(false)?;
        let realm_id = ctx.x0 as usize;
        let virtual_node = ctx.x1 as usize;
        let resp = RPCClient::new(node.extension.resource_server_ep).call::<resource_server::ResumeHostCondition>(&resource_server::Request::YieldTo {
            physical_node: node.node_index,
            realm_id,
            virtual_node,
            timeout: Some(bound as usize),
            // timeout: None,
        });
        ctx.pc += 4;
        node.tcb.write_all_registers(false, &mut ctx)?;
        // {
        //     let bound = node.upper_ns_bound_interrupt()?.unwrap();
        //     assert!(bound < 0);
        // }
        Ok(())
    }

    fn sys_direct(node: &mut VMMNode<Self>) -> Fallible<()> {
        let mut ctx = node.tcb.read_all_registers(false)?;
        let length = ctx.x0 as usize;
        let parameters = &[ctx.x1, ctx.x2, ctx.x3, ctx.x4, ctx.x5, ctx.x6][..length];
        let request = DirectRequest::recv_from_slice(parameters);
        let response = Self::direct(node, &request)?;
        let mut r = response.send_to_vec();
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

    #[cfg(feature = "benchmark")]
    fn direct(node: &mut VMMNode<Self>, request: &DirectRequest) -> Fallible<DirectResponse> {
        match request {
            DirectRequest::Start => {
                // debug_println!("host-vmm: bench start");
                let resp = RPCClient::new(node.extension.benchmark_server_ep)
                    .call::<benchmark_server::Response>(&benchmark_server::Request::Start);
                resp.unwrap();
            }
            DirectRequest::Finish => {
                // debug_println!("host-vmm: bench finish");
                let resp = RPCClient::new(node.extension.benchmark_server_ep)
                    .call::<benchmark_server::Response>(&benchmark_server::Request::Finish);
                resp.unwrap();
            }
        }
        Ok(DirectResponse)
    }

    #[cfg(not(feature = "benchmark"))]
    fn direct(node: &mut VMMNode<Self>, request: &DirectRequest) -> Fallible<DirectResponse> {
        panic!()
    }

}
