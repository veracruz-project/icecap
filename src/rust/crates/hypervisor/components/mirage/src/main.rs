#![no_std]
#![no_main]
#![feature(c_variadic)]
#![feature(new_uninit)]
#![feature(llvm_asm)]
#![allow(dead_code)]
#![allow(unused_variables)]

extern crate alloc;

use finite_set::Finite;
use hypervisor_event_server_types::{
    calls::Client as EventServerRequest, events, Bitfield as EventServerBitfield,
};
use hypervisor_mirage_config::Config;
use icecap_mirage_core::ocaml;
use icecap_std::{
    config::RingBufferKicksConfig, fmt::set_print_debug, prelude::*, ring_buffer::*, rpc,
    sel4::sys::c_types::c_int, sync::*,
};

mod syscall;
mod time_hack;

declare_main!(main);

static GLOBAL_STATE: DeferredMutex<Option<State>> =
    GenericMutex::new(DeferredMutexNotification::new(), None);

type NetIfaceId = usize;

pub struct State {
    event: Notification,
    event_server_bitfield: EventServerBitfield,
    net_ifaces: Vec<BufferedPacketRingBuffer>,
}

fn main(config: Config) -> Fallible<()> {
    set_print_debug();

    GLOBAL_STATE.set(config.lock);

    let event_server_bitfield = unsafe { EventServerBitfield::new(config.event_server_bitfield) };
    event_server_bitfield.clear_ignore_all();

    let net = BufferedPacketRingBuffer::new(PacketRingBuffer::new({
        let event_server = rpc::Client::<EventServerRequest>::new(config.event_server_endpoint);
        let index = {
            use events::*;
            RealmOut::RingBuffer(RealmRingBufferOut::Host(RealmRingBufferId::Net))
        };
        let kick = Box::new(move || {
            event_server.call::<()>(&EventServerRequest::Signal {
                index: index.to_nat(),
            })
        });
        RingBuffer::resume_from_config(
            &config.net_rb,
            RingBufferKicksConfig {
                read: kick.clone(),
                write: kick,
            },
        )
    }));

    net.packet_ring_buffer().enable_notify_read();
    net.packet_ring_buffer().enable_notify_write();

    let state = State {
        event: config.event,
        event_server_bitfield,
        net_ifaces: vec![net],
    };
    {
        let mut global_state = GLOBAL_STATE.lock();
        *global_state = Some(state);
    }

    syscall::init();

    let arg = config.passthru;

    println!("mirage enter");
    let ret = ocaml::run_main(&arg);
    println!("mirage exit: {:?}", ret);

    Ok(())
}

fn with<T, F: FnOnce(&mut State) -> T>(f: F) -> T {
    let mut state = GLOBAL_STATE.lock();
    let state = state.as_mut().unwrap();
    let ret = f(state);
    state.callback();
    ret
}

impl State {
    fn wfe(&mut self) {
        // TODO (must be notified of timeouts)
        // let badge = self.event.wait();
        // self.event_server_bitfield.clear_ignore(badge);
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
        f(
            buf.len(),
            Box::new(move |foreign_buf| foreign_buf.copy_from_slice(&buf)),
        )
    }
}

#[no_mangle]
extern "C" fn impl_wfe() {
    with(|s| s.wfe())
}

#[no_mangle]
extern "C" fn impl_get_time_ns() -> u64 {
    with(|s| time_hack::time_ns())
}

#[no_mangle]
extern "C" fn impl_set_timeout_ns(ns: u64) {
    with(|s| {
        // HACK
    })
}

#[no_mangle]
extern "C" fn impl_num_net_ifaces() -> usize {
    with(|s| s.net_ifaces.len())
}

#[no_mangle]
extern "C" fn impl_net_iface_poll(id: NetIfaceId) -> c_int {
    with(|s| s.net_ifaces[id].poll().is_some()) as c_int
}

#[no_mangle]
extern "C" fn impl_net_iface_tx(id: NetIfaceId, buf: *const u8, n: usize) {
    with(|s| {
        s.net_ifaces[id].tx(unsafe { core::slice::from_raw_parts(buf, n) });
    })
}

#[no_mangle]
extern "C" fn impl_net_iface_rx(id: NetIfaceId) -> usize {
    with(|s| {
        s.net_iface_rx(id, |n, f| {
            let bytes = ocaml::alloc(n);
            f(bytes.as_mut_slice());
            bytes.handle
        })
    })
}
