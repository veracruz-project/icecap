#![no_std]
#![no_main]
#![feature(alloc_prelude)]
#![feature(array_value_iter)]
#![feature(format_args_nl)]
#![feature(c_variadic)]
#![feature(type_ascription)]
#![feature(new_uninit)]
#![feature(slice_ptr_range)]
#![feature(const_mut_refs)]
#![allow(dead_code)]
#![allow(unused_comparisons)]
#![allow(unused_imports)]
#![allow(unused_variables)]

extern crate alloc;

use serde::{Serialize, Deserialize};

use icecap_std::prelude::*;
use sys::c_types::*;

mod c;
mod syscall;

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    test: String,
}

fn main(config: Config) -> Fallible<()> {
    debug_println!("from rust: {}", config.test);
    let state = Box::new(State);
    let ret = unsafe  {
        syscall::init();
        GLOBAL_STATE = Box::into_raw(state) as usize;
        c::costub_run_mirage()
    };
    debug_println!("mirage exit: {:?}", ret);
    Ok(())
}

static mut GLOBAL_STATE: usize = 0;

fn with<T, F: FnOnce(&mut State) -> T>(f: F) -> T {
    let mut state = unsafe {
        Box::from_raw(GLOBAL_STATE as *mut State)
    };
    let r = f(&mut state);
    Box::into_raw(state);
    r
}

type NetIfaceId = usize;

struct State;

impl State {
    fn wfe(&mut self) {
        todo!()
    }
}

#[no_mangle]
extern "C" fn impl_wfe() {
    with(|s| {
        s.wfe()
    })
}

#[no_mangle]
extern "C" fn impl_get_time_ns() -> u64 {
    todo!()
}

#[no_mangle]
extern "C" fn impl_set_timeout_ns(ns: u64) {
    todo!()
}

#[no_mangle]
extern "C" fn impl_num_net_ifaces() -> usize {
    todo!()
}

#[no_mangle]
extern "C" fn impl_net_iface_poll(id: NetIfaceId) -> c_int {
    todo!()
}

#[no_mangle]
extern "C" fn impl_net_iface_tx(id: NetIfaceId, buf: *const u8, n: usize) {
    todo!()
}

#[no_mangle]
extern "C" fn impl_net_iface_rx(id: NetIfaceId) -> usize {
    todo!()
}
