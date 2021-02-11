#![no_std]
#![no_main]
#![feature(format_args_nl)]

extern crate alloc;

mod device;

use icecap_std::prelude::*;
use icecap_qemu_ring_buffer_server_config::Config;

use crate::device::RingBufferDevice;

declare_main!(main);

fn main(config: Config) -> Fallible<()> {
    let device = RingBufferDevice::new(config.dev_vaddr);

    device.ctrl_r.set(config.layout.read.ctrl as u64);
    device.data_r.set(config.layout.read.data as u64);
    device.size_r.set(config.layout.read.size as u64);
    device.ctrl_w.set(config.layout.write.ctrl as u64);
    device.data_w.set(config.layout.write.data as u64);
    device.size_w.set(config.layout.write.size as u64);

    device.enable();

    let ready_signal = config.ready_signal;
    let wait = config.wait;
    let client_signal = config.client_signal;
    let irq_handler = config.irq_handler;

    const CLIENT_RX: u64 = 1 << 0;
    const CLIENT_TX: u64 = 1 << 1;
    const IRQ: u64 = 1 << 2;

    irq_handler.ack()?;
    ready_signal.signal();

    loop {
        let badge = wait.wait();
        if badge & (CLIENT_RX | CLIENT_TX) != 0 {
            device.notify();
        }
        if badge & IRQ != 0 {
            device.ack();
            client_signal.signal();
            irq_handler.ack()?;
        }
    }
}
