#![no_std]
#![no_main]
#![feature(llvm_asm)]

extern crate alloc;

use serde::{Serialize, Deserialize};

use icecap_std::prelude::*;
use icecap_std::rpc_sel4::*;
use icecap_start_generic::declare_generic_main;
use icecap_benchmark_server_types as benchmark_server;

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    benchmark_server_ep: Endpoint,
}

#[cfg(icecap_plat = "virt")]
const C: u32 = 10;
#[cfg(icecap_plat = "rpi4")]
const C: u32 = 1;

fn main(config: Config) -> Fallible<()> {
    let ep = config.benchmark_server_ep;

    let freq = read_cntfrq_el0();
    debug_println!("freq = {}", freq);

    let start = read_cntvct_el0();
    debug_println!("start = {}", start);

    let client = RPCClient::new(ep);

    client
        .call::<benchmark_server::Response>(&benchmark_server::Request::Start)
        .unwrap();

    for _ in 0..6 {
        loop {
            let t = read_cntvct_el0();
            if t % ((freq / C) as u64) == (0 as u64) {
                debug_println!("t = {}", t);
                break;
            }
            // sel4::yield_();
        }
    }

    client
        .call::<benchmark_server::Response>(&benchmark_server::Request::Finish)
        .unwrap();

    Ok(())
}

#[allow(deprecated)]
#[inline(never)]
pub fn read_cntfrq_el0() -> u32 {
    unsafe {
        let mut r: u32;
        llvm_asm!("mrs $0, cntfrq_el0" : "=r"(r));
        r
    }
}

#[allow(deprecated)]
#[inline(never)]
pub fn read_cntvct_el0() -> u64 {
    unsafe {
        let mut r: u64;
        llvm_asm!("mrs $0, cntvct_el0" : "=r"(r));
        r
    }
}
