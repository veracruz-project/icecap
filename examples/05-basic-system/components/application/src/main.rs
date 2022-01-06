#![no_std]
#![no_main]
#![feature(format_args_nl)]

extern crate alloc;

use serde::{Serialize, Deserialize};

use icecap_std::prelude::*;
use icecap_std::config::*;
use icecap_start_generic::declare_generic_main;

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    event_nfn: Notification,
    timer_server_ep: Endpoint,
    serial_server_ring_buffer: UnmanagedRingBufferConfig,
    badges: Badges,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Badges {
    timeout: Badge,
    serial_server_ring_buffer: Badge,
}

fn main(config: Config) -> Fallible<()> {

    let mut rb = RingBuffer::realize_unmanaged(&config.serial_server_ring_buffer);

    loop {
        let badge = config.event_nfn.wait();
        if badge & config.badges.timeout != 0 {

        }
        if badge & config.badges.serial_server_ring_buffer != 0 {

        } 
    }
}
