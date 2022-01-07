#![no_std]
#![no_main]
#![feature(drain_filter)]
#![feature(never_type)]

use icecap_benchmark_server_config::*;
use icecap_benchmark_server_types::*;
use icecap_std::prelude::*;
use icecap_std::rpc_sel4::*;

#[allow(dead_code)]
const NUM_NODES: usize = icecap_plat::NUM_CORES;

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {
    let ep = config.ep;
    let tcb = config.self_tcb;
    loop {
        let (info, _badge) = ep.recv();
        let request = rpc_server::recv::<Request>(&info);
        let response = handle(tcb, &request)?;
        rpc_server::reply(&response);
    }
}

#[cfg(not(icecap_benchmark))]
fn handle(_tcb: TCB, _request: &Request) -> Fallible<Response> {
    Ok(Err(()))
}

#[cfg(icecap_benchmark)]
fn handle(tcb: TCB, request: &Request) -> Fallible<Response> {
    match request {
        Request::Start => {
            debug_println!("benchmark-server: start");
            for affinity in 0..NUM_NODES {
                tcb.set_affinity(affinity as u64)?;
                sel4::benchmark::reset_log()?;
                sel4::benchmark::reset_all_thread_utilisation();
            }
        }
        Request::Finish => {
            for affinity in 0..NUM_NODES {
                tcb.set_affinity(affinity as u64)?;
                assert_eq!(sel4::benchmark::finalize_log(), 0);
                sel4::benchmark::dump_all_thread_utilisation();
            }
        }
    }
    Ok(Ok(InnerResponse))
}
