#![no_std]
#![no_main]
#![feature(drain_filter)]
#![feature(format_args_nl)]
#![feature(never_type)]
#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_variables)]
#![allow(unreachable_code)]

extern crate alloc;

use core::{
    cell::RefCell,
};
use alloc::{
    vec::Vec,
    collections::BTreeMap,
    rc::Rc,
    sync::Arc,
};

use icecap_std::{
    prelude::*,
    sync::*,
};
use icecap_rpc_sel4::*;
use icecap_benchmark_server_types::*;
use icecap_benchmark_server_config::*;

const NUM_NODES: usize = 4;

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

#[cfg(not(feature = "benchmark"))]
fn handle(tcb: TCB, request: &Request) -> Fallible<Response> {
    Ok(Err(()))
}

#[cfg(feature = "benchmark")]
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
            // debug_println!("benchmark-server: finish");
            for affinity in 0..NUM_NODES {
                tcb.set_affinity(affinity as u64)?;
                assert_eq!(sel4::benchmark::finalize_log(), 0);
                sel4::benchmark::dump_all_thread_utilisation();
            }
        }
    }
    Ok(Ok(InnerResponse))
}