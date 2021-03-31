#![no_std]
#![no_main]
#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_variables)]

extern crate alloc;

mod run;
mod event;
mod color;
mod plat;
mod device;

declare_main!(main);

use icecap_std::prelude::*;
use icecap_timer_server_client::*;
use icecap_serial_server_config::Config;

use run::{run, ClientId};
use event::Event;

pub fn main(config: Config) -> Fallible<()> {

    let timer = TimerClient::new(config.timer_ep_write);
    let clients = config.clients.iter().map(|client| {
        RingBuffer::realize(&client.ring_buffer)
    }).collect();

    let event_ep = config.ep;

    let cspace = config.cnode;
    let reply_ep = config.reply_ep;

    let dev = plat::serial_device(config.dev_vaddr);

    let irq_nfn = config.irq_nfn;
    let irq_handler = config.irq_handler;
    config.irq_thread.start(move || {
        loop {
            irq_nfn.wait();
            Event::Interrupt.send(&event_ep);
            irq_handler.ack().unwrap();
        }
    });

    let timer_wait = config.timer_wait;
    config.timer_thread.start(move || {
        loop {
            timer_wait.wait();
            Event::Timeout.send(&event_ep);
        }
    });

    for (i, client) in config.clients.iter().enumerate() {
        let nfn = client.ring_buffer.wait;
        client.thread.start(move || {
            loop {
                let badge = nfn.wait();
                Event::for_badge(badge, |ev| Event::Con(i as ClientId, ev).send(&event_ep));
            }
        });
    }

    run(clients, timer, event_ep, cspace, reply_ep, dev);
    Ok(())
}
