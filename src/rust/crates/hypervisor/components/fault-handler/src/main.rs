#![no_std]
#![no_main]

extern crate alloc;

use hypervisor_fault_handler_config::{Config, Thread};
use icecap_std::prelude::*;
use icecap_std::sel4::Fault;

declare_main!(main);

fn main(config: Config) -> Fallible<()> {
    let ep = config.ep;
    IPCBuffer::with_mut(|ipcbuf| loop {
        let (tag, badge) = ep.recv();
        let fault = Fault::get(ipcbuf, tag);
        handle(&config.threads[&badge], &fault)?;
    })
}

fn handle(thread: &Thread, fault: &Fault) -> Fallible<()> {
    println!("fault from {:?}: {:x?}", thread.name, fault);
    Ok(())
}
