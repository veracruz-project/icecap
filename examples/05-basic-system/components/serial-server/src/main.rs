#![no_std]
#![no_main]

extern crate alloc;

use serde::{Deserialize, Serialize};

use icecap_driver_interfaces::SerialDevice;
use icecap_pl011_driver::Pl011Device;
use icecap_start_generic::declare_generic_main;
use icecap_std::config::*;
use icecap_std::prelude::*;
use icecap_std::ring_buffer::{BufferedRingBuffer, RingBuffer};

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
    let dev = Pl011Device::new(config.dev_vaddr);
    dev.init();
    config.irq_handler.ack()?;

    let mut rb = BufferedRingBuffer::new(RingBuffer::unmanaged_from_config(
        &config.client_ring_buffer,
    ));
    rb.ring_buffer().enable_notify_read();
    rb.ring_buffer().enable_notify_write();

    loop {
        let badge = config.event_nfn.wait();

        if badge & config.badges.irq != 0 {
            while let Some(c) = dev.get_char() {
                rb.tx(&[c]);
            }
            dev.handle_interrupt();
            config.irq_handler.ack()?;
        }

        if badge & config.badges.client != 0 {
            rb.rx_callback();
            rb.tx_callback();
            if let Some(chars) = rb.rx() {
                for c in chars {
                    dev.put_char(c);
                }
            }
            rb.ring_buffer().enable_notify_read();
            rb.ring_buffer().enable_notify_write();
        }
    }
}
