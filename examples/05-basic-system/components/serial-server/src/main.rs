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

    let mut rb = BufferedRingBuffer::new(RingBuffer::realize_unmanaged(&config.client_ring_buffer));
    rb.ring_buffer().enable_notify_read();
    rb.ring_buffer().enable_notify_write();

    loop {
        let badge = config.event_nfn.wait();

        if badge & config.badges.irq != 0 {
            while let Some(c) = dev.get_char() {
                rb.tx(&[c]);
            }
            dev.handle_irq();
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
