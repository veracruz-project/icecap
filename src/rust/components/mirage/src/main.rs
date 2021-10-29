#![no_std]
#![no_main]
#![feature(alloc_prelude)]
#![feature(format_args_nl)]
#![feature(c_variadic)]
#![feature(new_uninit)]
#![allow(dead_code)]
#![allow(unused_variables)]
#![allow(unreachable_code)]

extern crate alloc;

use serde::{Serialize, Deserialize};

use icecap_std::prelude::*;
use icecap_std::config::*;
use icecap_std::sel4::sys::c_types::*;
use icecap_start_generic::declare_generic_main;

mod c;
mod syscall;
mod ocaml;

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    nfn: Notification,

    con: RingBufferConfig,
    net: RingBufferConfig,

    passthru: serde_json::Value,
}

fn main(config: Config) -> Fallible<()> {

    // NOTE
    // Commented out so that remainder is reachable, allowing for build test.

    // let net: BufferedPacketRingBuffer = panic!();
    // net.packet_ring_buffer().enable_notify_read();
    // net.packet_ring_buffer().enable_notify_write();

    // let state = State {
    //     nfn: config.nfn,
    //     net_ifaces: vec![net],
    // };
    // unsafe  {
    //     GLOBAL_STATE = Some(state);
    // };

    syscall::init();

    let arg = serde_json::to_vec(&serde_json::json!({
        "network_config": config.passthru,
    })).unwrap();

    println!("mirage enter");
    let ret = ocaml::run(&arg);
    println!("mirage exit: {:?}", ret);

    Ok(())
}

static mut GLOBAL_STATE: Option<State> = None;

fn with<T, F: FnOnce(&mut State) -> T>(f: F) -> T {
    unsafe {
        let s = &mut GLOBAL_STATE.as_mut().unwrap();
        let r = f(s);
        s.callback();
        r
    }
}

type NetIfaceId = usize;

pub struct State {
    nfn: Notification,
    net_ifaces: Vec<BufferedPacketRingBuffer>,
}

impl State {
    fn wfe(&mut self) {
        self.nfn.wait();
    }

    fn callback(&mut self) {
        for id in 0..self.net_ifaces.len() {
            self.net_ifaces[id].rx_callback();
            self.net_ifaces[id].tx_callback();
        }
    }

    pub fn net_iface_rx<F, T>(&mut self, id: NetIfaceId, f: F) -> T
    where
        F: FnOnce(usize, Box<dyn FnOnce(&mut [u8])>) -> T,
    {
        let buf = self.net_ifaces[id].rx().unwrap();
        f(buf.len(), Box::new(move |foreign_buf| {
            foreign_buf.copy_from_slice(&buf)
        }))
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
    with(|s| {
        panic!()
    })
}

#[no_mangle]
extern "C" fn impl_set_timeout_ns(ns: u64) {
    with(|s| {
        panic!()
    })
}

#[no_mangle]
extern "C" fn impl_num_net_ifaces() -> usize {
    with(|s| {
        s.net_ifaces.len()
    })
}

#[no_mangle]
extern "C" fn impl_net_iface_poll(id: NetIfaceId) -> c_int {
    with(|s| {
        s.net_ifaces[id].poll().is_some()
    }) as c_int
}

#[no_mangle]
extern "C" fn impl_net_iface_tx(id: NetIfaceId, buf: *const u8, n: usize) {
    with(|s| {
        s.net_ifaces[id].tx(unsafe {
            core::slice::from_raw_parts(buf, n)
        });
    })
}

#[no_mangle]
extern "C" fn impl_net_iface_rx(id: NetIfaceId) -> usize {
    with(|s| {
        s.net_iface_rx(id, |n, f| {
            let mut handle = 0;
            let mut buf = core::ptr::null_mut();
            unsafe {
                c::costub_alloc(n, &mut handle, &mut buf);
            }
            f(unsafe {
                core::slice::from_raw_parts_mut(buf, n)
            });
            handle
        })
    })
}
