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
use icecap_std::finite_set::Finite;
use icecap_std::rpc_sel4::RPCClient;
use icecap_std::config::RingBufferKicksConfig;
use icecap_timer_server_client::*;
use icecap_serial_server_config::Config;

use icecap_event_server_types::calls::Client as EventServerRequest;
use icecap_event_server_types::events;

use run::{run, ClientId};
use event::Event;

pub fn main(config: Config) -> Fallible<()> {

    let timer = TimerClient::new(config.timer_ep_write);

    let event_server = RPCClient::<EventServerRequest>::new(config.event_server);
    let mk_signal = move |index: events::SerialServerOut| -> icecap_std::ring_buffer::Kick {
        let event_server = event_server.clone();
        let index = index.to_nat();
        Box::new(move || event_server.call::<()>(&EventServerRequest::Signal {
            index,
        }))
    };
    let mk_kicks = |rb: events::SerialServerRingBuffer| {
        RingBufferKicksConfig {
            read: mk_signal(events::SerialServerOut::RingBuffer(
                rb.clone(),
                events::RingBufferSide::Read,
            )),
            write: mk_signal(events::SerialServerOut::RingBuffer(
                rb.clone(),
                events::RingBufferSide::Write,
            )),
        }
    };

    let mut clients = vec![];
    clients.push(RingBuffer::realize(
        &config.host_client.ring_buffer,
        mk_kicks(events::SerialServerRingBuffer::Host),
    ));
    for (i, realm) in config.realm_clients.iter().enumerate() {
        clients.push(RingBuffer::realize(
            &realm.ring_buffer,
            mk_kicks(events::SerialServerRingBuffer::Realm(events::RealmId(i))),
        ));
    }

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

    for (i, client) in core::iter::once(&config.host_client).chain(config.realm_clients.iter()).enumerate() {
        let nfn = client.wait;
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
