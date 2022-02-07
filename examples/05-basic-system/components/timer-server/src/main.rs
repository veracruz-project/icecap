#![no_std]
#![no_main]

extern crate alloc;

use core::convert::TryFrom;

use serde::{Deserialize, Serialize};

use icecap_driver_interfaces::TimerDevice;
use icecap_start_generic::declare_generic_main;
use icecap_std::{prelude::*, rpc};
use icecap_virt_timer_driver::VirtTimerDevice;

use timer_server_types::{Request, NS_IN_S};

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    loop_ep: Endpoint,
    dev_vaddr: usize,
    irq_handler: IRQHandler,
    client_timeout: Notification,
    badges: Badges,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Badges {
    irq: Badge,
    client: Badge,
}

fn main(config: Config) -> Fallible<()> {
    let dev = VirtTimerDevice::new(config.dev_vaddr);
    dev.set_enable(false);
    dev.clear_interrupt();
    config.irq_handler.ack()?;

    let freq = dev.get_freq().into();
    let ns_to_ticks = |ns| convert(ns, freq, NS_IN_S);
    let ticks_to_ns = |ticks| convert(ticks, NS_IN_S, freq);

    let mut compare_state: Option<u64> = None;

    loop {
        enum Received {
            Interrupt,
            Client(Request),
            Unknown,
        }
        let received = rpc::server::recv(config.loop_ep, |mut receiving| {
            if receiving.badge & config.badges.irq != 0 {
                Received::Interrupt
            } else if receiving.badge & config.badges.client != 0 {
                Received::Client(receiving.read())
            } else {
                Received::Unknown
            }
        });
        match received {
            Received::Interrupt => {
                if let Some(compare) = compare_state {
                    if compare <= dev.get_count() {
                        compare_state = None;
                        config.client_timeout.signal();
                        dev.set_enable(false);
                    }
                }
                dev.clear_interrupt();
                config.irq_handler.ack()?;
            }
            Received::Client(Request::SetTimeout(ns)) => {
                let ticks = ns_to_ticks(ns);
                let compare = ticks + dev.get_count();
                compare_state = Some(compare);
                dev.set_compare(compare);
                dev.set_enable(true);
                rpc::server::reply(&());
            }
            Received::Client(Request::GetTime) => {
                let ticks = dev.get_count();
                let response = ticks_to_ns(ticks);
                rpc::server::reply(&response);
            }
            Received::Unknown => {}
        }
    }
}

// NOTE this function is correct on the domain relevant to this example
fn convert(value: u64, numerator: u64, denominator: u64) -> u64 {
    u64::try_from((u128::from(value) * u128::from(numerator)) / u128::from(denominator)).unwrap()
}
