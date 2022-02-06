#![no_std]
#![no_main]
#![feature(drain_filter)]
#![feature(never_type)]

use hypervisor_benchmark_server_config::*;
use hypervisor_benchmark_server_types::*;
use icecap_std::prelude::*;
use icecap_std::rpc;

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {
    let ep = config.ep;
    let tcb = config.self_tcb;
    IPCBuffer::with_mut(|ipcbuf| loop {
        let request = rpc::server::recv_with_ipcbuf(ipcbuf, ep, |mut receiving| receiving.read());
        let response = handle(tcb, &request)?;
        rpc::server::reply_with_ipcbuf(ipcbuf, &response);
    })
}

cfg_if::cfg_if! {
    if #[cfg(icecap_benchmark)] {
        use icecap_plat::NUM_CORES;

        fn handle(tcb: TCB, request: &Request) -> Fallible<Response> {
            match request {
                Request::Start => {
                    debug_println!("benchmark-server: start");
                    for affinity in 0..NUM_CORES {
                        tcb.set_affinity(affinity as u64)?;
                        sel4::benchmark::reset_log()?;
                        sel4::benchmark::reset_all_thread_utilisation();
                    }
                }
                Request::Finish => {
                    for affinity in 0..NUM_CORES {
                        tcb.set_affinity(affinity as u64)?;
                        assert_eq!(sel4::benchmark::finalize_log(), 0);
                        sel4::benchmark::dump_all_thread_utilisation();
                    }
                }
            }
            Ok(Ok(InnerResponse))
        }
    } else {
        fn handle(_tcb: TCB, _request: &Request) -> Fallible<Response> {
            Ok(Err(Error))
        }
    }
}
