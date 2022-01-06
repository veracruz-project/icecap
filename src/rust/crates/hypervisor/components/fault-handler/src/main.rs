#![no_std]
#![no_main]

extern crate alloc;

use icecap_std::prelude::*;
use icecap_fault_handler_config::{Config, Thread};
use sel4::Fault;

declare_main!(main);

fn main(config: Config) -> Fallible<()> {
    let ep = config.ep;
    loop {
        let (tag, badge) = ep.recv();
        let fault = Fault::get(tag);
        handle(&config.threads[&badge], &fault)?;
    }
}

fn handle(thread: &Thread, fault: &Fault) -> Fallible<()> {
    println!("fault for {:?}: {:x?}", thread.name, fault);
    Ok(())
}
