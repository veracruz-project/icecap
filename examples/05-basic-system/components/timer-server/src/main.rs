#![no_std]
#![no_main]

extern crate alloc;

use serde::{Serialize, Deserialize};

use icecap_std::prelude::*;
use icecap_start_generic::declare_generic_main;
pub use icecap_drivers::timer::{TimerDevice, QemuTimerDevice};

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

    let dev = QemuTimerDevice::new(config.dev_vaddr);
    config.irq_handler.ack()?;

    let second = dev.get_freq() as u64;

    loop {
        let count = dev.get_count();
        debug_println!("count {}", count);
        dev.set_compare(count + second);
        dev.set_enable(true);
        let (info, badge) = config.loop_ep.recv();
        if badge & config.badges.irq != 0 {
            dev.set_enable(false);
            dev.clear_interrupt();
            config.irq_handler.ack()?;
        }
        if badge & config.badges.client != 0 {

        } 
    }
}
