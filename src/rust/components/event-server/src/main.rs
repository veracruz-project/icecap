#![no_std]
#![no_main]
#![feature(drain_filter)]
#![feature(format_args_nl)]
#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_variables)]

extern crate alloc;

use icecap_std::prelude::*;
use icecap_event_server_config::Config;

declare_main!(main);

pub fn main(config: Config) -> Fallible<()> {
    Ok(())
}
