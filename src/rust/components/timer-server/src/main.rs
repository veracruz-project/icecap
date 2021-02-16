#![no_std]
#![no_main]
#![feature(drain_filter)]
#![feature(format_args_nl)]
#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_variables)]

extern crate alloc;

use icecap_std::prelude::*;
use icecap_timer_server_config::Config;

mod run;
mod server;
mod device;
mod plat;

use run::run;

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {
    let irq_nfn = config.irq_nfn;
    let ep_write = config.ep_write;
    let irq_handler = config.irq_handler;
    config.irq_thread.start(move || {
        loop {
            irq_nfn.wait();
            ep_write.call(MessageInfo::new(0, 0, 0, 0));
            irq_handler.ack().unwrap();
        }
    });
    run(config.cnode, config.reply_ep, config.dev_vaddr, config.ep_read, config.clients.clone())
}
