#![no_std]
#![no_main]

extern crate alloc;

use serde::{Serialize, Deserialize};

use icecap_std::prelude::*;
use icecap_std::config::*;
use icecap_start_generic::declare_generic_main;
use icecap_drivers::serial::{SerialDevice, VirtSerialDevice};

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    dev_vaddr: usize,
    event_nfn: Notification,
    irq_handler: IRQHandler,
    client_ring_buffer: UnmanagedRingBufferConfig,
    badges: Badges,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Badges {
    irq: Badge,
    client: Badge,
}

fn main(config: Config) -> Fallible<()> {

    let dev = VirtSerialDevice::new(config.dev_vaddr);
    dev.init();
    config.irq_handler.ack()?;

    let mut rb = RingBuffer::realize_unmanaged(&config.client_ring_buffer);

    loop {

        while let Some(c) = dev.get_char() {
            dev.put_char(b'<');
            dev.put_char(c);
            dev.put_char(b'>');
        }

        let badge = config.event_nfn.wait();
        if badge & config.badges.irq != 0 {
            dev.put_char(b'+');
            dev.handle_irq();
            config.irq_handler.ack()?;
        }
        if badge & config.badges.client != 0 {

        } 
    }
}
