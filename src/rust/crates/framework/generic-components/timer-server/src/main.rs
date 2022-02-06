#![no_std]
#![no_main]
#![feature(drain_filter)]
#![feature(never_type)]

extern crate alloc;

use alloc::sync::Arc;

use icecap_driver_interfaces::TimerDevice;
use icecap_generic_timer_server_config::Config;
use icecap_generic_timer_server_types::Request;
use icecap_std::{prelude::*, rpc, sync::*};

use crate::{plat::timer_device, server::Server};

mod server;
mod plat;

const TIMERS_PER_CLIENT: i64 = 1;
const INTERRUPT_BADGE: Word = 1;
const CLIENT_BADGE_START: Word = INTERRUPT_BADGE + 1;

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {
    let device = timer_device(config.dev_vaddr);
    let server = Server::new(config.clients, TIMERS_PER_CLIENT, device);
    let server = Arc::new(Mutex::new(
        ExplicitMutexNotification::new(config.lock),
        server,
    ));

    for ((endpoint, irq_handler), thread) in config
        .endpoints
        .iter()
        .zip(config.irq_handlers.iter())
        .skip(1)
        .zip(&config.secondary_threads)
    {
        thread.start({
            let server = server.clone();
            let endpoint = *endpoint;
            let irq_handler = *irq_handler;
            move || run(&server, endpoint, irq_handler).unwrap()
        })
    }

    run(&server, config.endpoints[0], config.irq_handlers[0])?
}

pub fn run(
    server: &Mutex<Server<impl TimerDevice>>,
    endpoint: Endpoint,
    irq_handler: IRQHandler,
) -> Fallible<!> {
    loop {
        enum Received {
            Interrupt,
            Client { cid: usize, req: Request },
        }
        let received = rpc::server::recv(endpoint, |mut receiving| match receiving.badge {
            INTERRUPT_BADGE => Received::Interrupt,
            _ => Received::Client {
                cid: receiving.badge as usize - CLIENT_BADGE_START as usize,
                req: receiving.read(),
            },
        });

        let mut server = server.lock();
        match received {
            Received::Interrupt => {
                server.handle_interrupt();
                irq_handler.ack().unwrap();
            }
            Received::Client { cid, req } => match req {
                Request::Completed => panic!(), // rpc::server::reply(server.completed(cid)),
                Request::Periodic { tid, ns } => {
                    rpc::server::reply(&server.periodic(cid, tid, ns as i64))
                }
                Request::OneshotAbsolute { tid, ns } => {
                    rpc::server::reply(&server.oneshot_absolute(cid, tid, ns as i64))
                }
                Request::OneshotRelative { tid, ns } => {
                    rpc::server::reply(&server.oneshot_relative(cid, tid, ns as i64))
                }
                Request::Stop { tid } => rpc::server::reply(&server.stop(cid, tid)),
                Request::Time => rpc::server::reply(&(server.time(cid) as u64)),
            },
        }
    }
}
