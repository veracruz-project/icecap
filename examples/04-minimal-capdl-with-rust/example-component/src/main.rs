#![no_std]
#![no_main]
#![feature(format_args_nl)]

extern crate alloc;

use icecap_std::prelude::*;

declare_main!(main);

// TODO multiple threads
// TODO mutex

fn main(config: example_component_config::Config) -> Fallible<()> {
    debug_println!("{:#?}", config);
    Ok(())
}
