#![no_std]
#![no_main]

extern crate alloc;

use core::convert::TryFrom;

use serde::{Deserialize, Serialize};

use icecap_driver_interfaces::TimerDevice;
use icecap_start_generic::declare_generic_main;
use icecap_std::{prelude::*, rpc_sel4::rpc_server};
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
        let (info, badge) = config.loop_ep.recv();
        if badge & config.badges.irq != 0 {
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
        if badge & config.badges.client != 0 {
            match rpc_server::recv::<Request>(&info) {
                Request::SetTimeout(ns) => {
                    let ticks = ns_to_ticks(ns);
                    let compare = ticks + dev.get_count();
                    compare_state = Some(compare);
                    dev.set_compare(compare);
                    dev.set_enable(true);
                    rpc_server::reply(&());
                }
                Request::GetTime => {
                    let ticks = dev.get_count();
                    let response = ticks_to_ns(ticks);
                    rpc_server::reply(&response);
                }
            }
        }
    }
}

// NOTE this function is correct on the domain relevant to this example
fn convert(value: u64, numerator: u64, denominator: u64) -> u64 {
    u64::try_from((u128::from(value) * u128::from(numerator)) / u128::from(denominator)).unwrap()
}
