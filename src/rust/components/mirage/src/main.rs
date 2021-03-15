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
use icecap_std::config::*;
use icecap_std::config_realize::*;
use icecap_start_generic::declare_generic_main;
use sys::c_types::*;

mod c;
mod syscall;
mod ocaml;

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    event_ep: Endpoint,

    timer: DescTimerClient,
    con: DescMappedRingBuffer,
    net: DescMappedRingBuffer,

    timer_thread: Thread,
    net_thread: Thread,

    passthru: serde_json::Value,
}

fn main(config: Config) -> Fallible<()> {
    {
        let timer_wait = config.timer.wait;
        let event_send = config.event_ep;
        config.timer_thread.start(move || {
            loop {
                timer_wait.wait();
                event_send.send(MessageInfo::empty());
            }
        });
    }
    {
        let net_wait = config.net.wait;
        let event_send = config.event_ep;
        config.net_thread.start(move || {
            loop {
                net_wait.wait();
                event_send.send(MessageInfo::empty());
            }
        });
    }

    let con_rb = realize_mapped_ring_buffer(&config.con);
    let con = ConDriver::new(con_rb);
    icecap_std::set_print(con);

    let net = NetDriver::new(PacketRingBuffer::new(realize_mapped_ring_buffer(&config.net)));
    net.packet_ring_buffer().enable_notify_read();
    net.packet_ring_buffer().enable_notify_write();

    let state = State {
        event_ep: config.event_ep,
        timer: realize_timer_client(&config.timer),
        net_ifaces: vec![net],
    };
    unsafe  {
        GLOBAL_STATE = Some(state);
    };

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
    event_ep: Endpoint,
    timer: Timer,
    // con: ConDriver, // TODO
    net_ifaces: Vec<NetDriver>,
}

impl State {
    fn wfe(&mut self) {
        self.event_ep.recv();
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
        s.timer.time()
    })
}

#[no_mangle]
extern "C" fn impl_set_timeout_ns(ns: u64) {
    with(|s| {
        s.timer.oneshot_absolute(0, ns).unwrap()
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
