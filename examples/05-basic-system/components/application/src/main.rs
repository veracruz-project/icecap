#![no_std]
#![no_main]

extern crate alloc;

use core::mem;
use core::fmt::{self, Write};
use core::convert::TryFrom;
use alloc::collections::VecDeque;

use serde::{Serialize, Deserialize};

use icecap_std::prelude::*;
use icecap_std::config::*;
use icecap_std::rpc_sel4::RPCClient;
use icecap_start_generic::declare_generic_main;

use timer_server_types::{Request, Nanoseconds, NS_IN_S};

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

struct Interaction {
    serial_client: BufferedRingBuffer,
    timer_client: RPCClient<Request>,
    awaiting_timeout: bool,
    queued_lines: VecDeque<String>,
    current_line: String,
}

macro_rules! out {
    ($dst:expr, $($arg:tt)*) => ($crate::Writer($dst).write_fmt(format_args!($($arg)*)).unwrap());
}

fn main(config: Config) -> Fallible<()> {

    let mut interaction = Interaction {
        serial_client: BufferedRingBuffer::new(RingBuffer::realize_unmanaged(&config.serial_server_ring_buffer)),
        timer_client: RPCClient::<Request>::new(config.timer_server_ep),
        awaiting_timeout: false,
        queued_lines: VecDeque::new(),
        current_line: String::new(),
    };

    interaction.init();

    loop {
        let badge = config.event_nfn.wait();
        if badge & config.badges.timeout != 0 {
            interaction.handle_timeout_event();
        }
        if badge & config.badges.serial_server_ring_buffer != 0 {
            interaction.handle_serial_server_ring_buffer_event();
        } 
    }
}

impl Interaction {

    fn init(&mut self) {
        self.enable_serial_server_ring_buffer_events();
        self.prompt();
    }

    fn enable_serial_server_ring_buffer_events(&mut self) {
        self.serial_client.ring_buffer().enable_notify_read();
        self.serial_client.ring_buffer().enable_notify_write();
    }

    fn prompt(&mut self) {
        let time = self.timer_client.call::<Nanoseconds>(&Request::GetTime);
        out!(&mut self.serial_client, "[{}] $ ", time);
    }

    fn handle_timeout_event(&mut self) {
        assert!(self.awaiting_timeout);
        self.prompt();
        if self.queued_lines.is_empty() {
            for c in self.current_line.chars() {
                out!(&mut self.serial_client, "{}", c);
            }
            self.awaiting_timeout = false;
        } else {
            let complete_line = self.queued_lines.pop_front().unwrap();
            for c in complete_line.chars() {
                out!(&mut self.serial_client, "{}", c);
            }
            let ns = interpret_line(&complete_line).unwrap();
            self.timer_client.call::<()>(&Request::SetTimeout(ns));
            out!(&mut self.serial_client, "\n");
        }
    }

    fn handle_serial_server_ring_buffer_event(&mut self) {
        self.serial_client.rx_callback();
        self.serial_client.tx_callback();
        if let Some(chars) = self.serial_client.rx() {
            for c in chars.iter() {
                match c {
                    b'0'..=b'9' | b'.' => {
                        let c = (*c).into();
                        self.current_line.push(c);
                        if !self.awaiting_timeout {
                            out!(&mut self.serial_client, "{}", c);
                        }
                    }
                    b'\r' => {
                        if self.awaiting_timeout {
                            let mut complete_line = String::new();
                            mem::swap(&mut complete_line, &mut self.current_line);
                            self.queued_lines.push_back(complete_line);
                        } else {
                            let ns = interpret_line(&self.current_line).unwrap();
                            self.current_line.clear();
                            self.timer_client.call::<()>(&Request::SetTimeout(ns));
                            out!(&mut self.serial_client, "\n");
                            self.awaiting_timeout = true;
                        }
                    }
                    _ => {
                    }
                }
            }
        }
        self.enable_serial_server_ring_buffer_events()
    }
}

struct Writer<'a>(pub &'a mut BufferedRingBuffer);

impl fmt::Write for Writer<'_> {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        self.0.tx(s.as_bytes());
        Ok(())
    }
}

// NOTE this function is correct on the domain relevant to this example
fn interpret_line(s: &str) -> Option<Nanoseconds> {
    str::parse::<f64>(s).map(|seconds| {
        unsafe {
            (seconds * f64::try_from(u32::try_from(NS_IN_S).unwrap()).unwrap()).to_int_unchecked()
        }
    }).ok()
}
