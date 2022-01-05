#![no_std]
#![no_main]
#![feature(format_args_nl)]

extern crate alloc;

use serde::{Serialize, Deserialize};

use icecap_std::prelude::*;
use icecap_start_generic::declare_generic_main;

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
}

fn main(config: Config) -> Fallible<()> {
    debug_println!("{:#?}", config);
    Ok(())
}
