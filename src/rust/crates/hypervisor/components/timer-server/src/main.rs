#![no_std]
#![no_main]
#![feature(drain_filter)]
#![feature(never_type)]

extern crate alloc;

use alloc::sync::Arc;

use icecap_driver_interfaces::TimerDevice;
use icecap_std::{prelude::*, rpc_sel4::*, sync::*};
use icecap_timer_server_config::Config;
use icecap_timer_server_types::Request;

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
        // TODO can use seL4_ReplyRecv once switch to MCS
        let (recv_info, badge) = endpoint.recv();

        {
            let mut server = server.lock();
            match badge {
                INTERRUPT_BADGE => {
                    server.handle_interrupt();
                    irq_handler.ack().unwrap();
                }
                _ => {
                    let cid: usize = badge as usize - CLIENT_BADGE_START as usize;
                    reply(match rpc_server::recv(&recv_info) {
                        Request::Completed => panic!(), // rpc_server::prepare(server.completed(cid)),
                        Request::Periodic { tid, ns } => {
                            rpc_server::prepare(&server.periodic(cid, tid, ns as i64))
                        }
                        Request::OneshotAbsolute { tid, ns } => {
                            rpc_server::prepare(&server.oneshot_absolute(cid, tid, ns as i64))
                        }
                        Request::OneshotRelative { tid, ns } => {
                            rpc_server::prepare(&server.oneshot_relative(cid, tid, ns as i64))
                        }
                        Request::Stop { tid } => rpc_server::prepare(&server.stop(cid, tid)),
                        Request::Time => rpc_server::prepare(&(server.time(cid) as u64)),
                    })
                }
            }
        }
    }
}
