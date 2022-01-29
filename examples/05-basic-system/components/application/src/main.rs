#![no_std]
#![no_main]

extern crate alloc;

use core::fmt::Write;

use serde::{Deserialize, Serialize};

use icecap_start_generic::declare_generic_main;
use icecap_std::config::*;
use icecap_std::prelude::*;
use icecap_std::ring_buffer::*;
use icecap_std::rpc;

use timer_server_types::{Nanoseconds, Request, NS_IN_S};

mod fmt;

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

struct State {
    serial_client: BufferedRingBuffer,
    timer_client: rpc::Client<Request>,
}

fn main(config: Config) -> Fallible<()> {
    let mut state = State {
        serial_client: BufferedRingBuffer::new(RingBuffer::unmanaged_from_config(
            &config.serial_server_ring_buffer,
        )),
        timer_client: rpc::Client::<Request>::new(config.timer_server_ep),
    };

    state.init();

    loop {
        let badge = config.event_nfn.wait();
        if badge & config.badges.timeout != 0 {
            state.handle_timeout_event();
        }
        if badge & config.badges.serial_server_ring_buffer != 0 {
            state.handle_serial_server_ring_buffer_event();
        }
    }
}

impl State {
    const TICK: Nanoseconds = NS_IN_S;

    fn init(&mut self) {
        self.enable_serial_server_ring_buffer_events();
        self.tick();
    }

    fn enable_serial_server_ring_buffer_events(&mut self) {
        self.serial_client.ring_buffer().enable_notify_read();
        self.serial_client.ring_buffer().enable_notify_write();
    }

    fn tick(&mut self) {
        let time = self.timer_client.call::<Nanoseconds>(&Request::GetTime);
        out!(&mut self.serial_client, "time: {} ns\n", time);
        self.timer_client
            .call::<()>(&Request::SetTimeout(Self::TICK));
    }

    fn handle_timeout_event(&mut self) {
        self.tick()
    }

    fn handle_serial_server_ring_buffer_event(&mut self) {
        self.serial_client.rx_callback();
        self.serial_client.tx_callback();
        if let Some(chars) = self.serial_client.rx() {
            for c in chars.iter() {
                out!(&mut self.serial_client, "input: {:?}\n", char::from(*c));
            }
        }
        self.enable_serial_server_ring_buffer_events()
    }
}
