#![no_std]
#![no_main]
#![feature(format_args_nl)]

extern crate alloc;

use icecap_std::prelude::*;
use icecap_std::sel4::fault::*;
use icecap_std::finite_set::Finite;
use icecap_rpc_sel4::*;
use icecap_host_vmm_config::*;
use icecap_vmm::*;
use icecap_host_vmm_types::{sys_id, DirectRequest, DirectResponse};

#[allow(unused_imports)]
use icecap_benchmark_server_types as benchmark_server;

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {

    let resource_server_ep = config.resource_server_ep;
    let event_server_client_ep = config.event_server_client_ep;
    let event_server_control_ep = config.event_server_control_ep;
    let benchmark_server_ep = config.benchmark_server_ep;

    let irq_map = IRQMap {
        ppi: config.ppi_map.into_iter().map(|(ppi, (in_index, must_ack))| (ppi, (in_index.to_nat(), must_ack))).collect(),
        spi: config.spi_map.into_iter().map(|(spi, (in_index, nid, must_ack))| (spi, (in_index.to_nat(), nid, must_ack))).collect(),
    };

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
                event_server_bitfield: node.event_server_bitfield,
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
    #[allow(dead_code)]
    event_server_control_ep: Endpoint,
    #[allow(dead_code)]
    benchmark_server_ep: Endpoint,
}

impl VMMExtension for Extension {

    fn handle_wf(_node: &mut VMMNode<Self>) -> Fallible<()> {
        panic!()
    }

    fn handle_syscall(node: &mut VMMNode<Self>, fault: &UnknownSyscall) -> Fallible<()> {
        Ok(match fault.syscall {
            sys_id::RESOURCE_SERVER_PASSTHRU => {
                Self::sys_resource_server_passthru(node, fault)?
            }
            sys_id::DIRECT => {
                Self::sys_direct(node, fault)?
            }
            _ => {
                panic!("unknown syscall: {:?}", fault)
            }
        })
    }

    fn handle_putchar(_node: &mut VMMNode<Self>, c: u8) -> Fallible<()> {
        debug_print!("{}", c as char);
        Ok(())
    }
}

impl Extension {

    fn userspace_syscall(
        node: &mut VMMNode<Self>,
        fault: &UnknownSyscall,
        f: impl FnOnce(&mut VMMNode<Self>, &[u64]) -> Fallible<Vec<u64>>
    ) -> Fallible<()> {
        let length = fault.x0 as usize;
        let parameters = (0..length).map(|i| fault.gpr(i + 1)).collect::<Vec<u64>>();
        let mut r = f(node, &parameters)?;
        assert!(r.len() <= 6);
        UnknownSyscall::mr_gpr(0).set(r.len() as u64);
        r.resize_with(6, || 0);
        for i in 0..6 {
            UnknownSyscall::mr_gpr(i + 1).set(r[i]);
        }
        fault.advance_and_reply();
        Ok(())
    }

    fn sys_resource_server_passthru(node: &mut VMMNode<Self>, fault: &UnknownSyscall) -> Fallible<()> {
        Self::userspace_syscall(node, fault, |node, values| {
            let recv_info = node.extension.resource_server_ep.call(proxy::up(values));
            let resp = proxy::down(&recv_info);
            Ok(resp)
        })
    }

    fn sys_direct(node: &mut VMMNode<Self>, fault: &UnknownSyscall) -> Fallible<()> {
        Self::userspace_syscall(node, fault, |node, values| {
            let request = DirectRequest::recv_from_slice(&values);
            let response = Self::direct(node, &request)?;
            Ok(response.send_to_vec())
        })
    }

    #[cfg(icecap_benchmark)]
    fn direct(node: &mut VMMNode<Self>, request: &DirectRequest) -> Fallible<DirectResponse> {
        match request {
            DirectRequest::BenchmarkUtilisationStart => {
                RPCClient::new(node.extension.benchmark_server_ep)
                    .call::<benchmark_server::Response>(&benchmark_server::Request::Start)
                    .unwrap();
            }
            DirectRequest::BenchmarkUtilisationFinish => {
                RPCClient::new(node.extension.benchmark_server_ep)
                    .call::<benchmark_server::Response>(&benchmark_server::Request::Finish)
                    .unwrap();
            }
        }
        Ok(DirectResponse)
    }

    #[cfg(not(icecap_benchmark))]
    fn direct(_node: &mut VMMNode<Self>, _request: &DirectRequest) -> Fallible<DirectResponse> {
        panic!()
    }

}
