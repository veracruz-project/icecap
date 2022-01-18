#![no_std]
#![no_main]

extern crate alloc;

use serde::{Deserialize, Serialize};

use icecap_start_generic::declare_generic_main;
use icecap_std::prelude::*;

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    nfn: Notification,
}

fn main(config: Config) -> Fallible<()> {
    debug_println!("Hello from subsystem");
    config.nfn.signal();
    Ok(())
}
