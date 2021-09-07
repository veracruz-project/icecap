#![no_std]
#![no_main]
#![feature(alloc_prelude)]
#![feature(array_value_iter)]
#![feature(format_args_nl)]
#![feature(c_variadic)]
#![feature(type_ascription)]
#![feature(new_uninit)]
#![feature(slice_ptr_range)]
#![feature(llvm_asm)]
#![feature(const_mut_refs)]
#![allow(dead_code)]
#![allow(unused_comparisons)]
#![allow(unused_imports)]
#![allow(unused_variables)]

extern crate alloc;

use serde::{Serialize, Deserialize};

use icecap_std::prelude::*;
use icecap_std::rpc_sel4::*;
use icecap_start_generic::declare_generic_main;
use icecap_benchmark_server_types as benchmark_server;

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    bep: Endpoint,
}

#[cfg(icecap_plat = "virt")]
const C: u32 = 10;
#[cfg(icecap_plat = "rpi4")]
const C: u32 = 1;

fn main(config: Config) -> Fallible<()> {
    let ep = config.bep;

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

#[inline(never)]
pub fn read_cntfrq_el0() -> u32 {
    unsafe {
        let mut r: u32;
        llvm_asm!("mrs $0, cntfrq_el0" : "=r"(r));
        r
    }
}

#[inline(never)]
pub fn read_cntvct_el0() -> u64 {
    unsafe {
        let mut r: u64;
        llvm_asm!("mrs $0, cntvct_el0" : "=r"(r));
        r
    }
}
