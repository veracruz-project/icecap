#![no_std]
#![no_main]
#![feature(format_args_nl)]

extern crate alloc;

use icecap_std::prelude::*;

declare_main!(main);

fn main(config: minimal_config::Config) -> Fallible<()> {
    debug_println!("{:#?}", config);
    Ok(())
}
