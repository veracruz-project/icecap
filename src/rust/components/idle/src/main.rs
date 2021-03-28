#![no_std]
#![no_main]
#![feature(format_args_nl)]
#![allow(dead_code)]
#![allow(unused_variables)]

extern crate alloc;

use icecap_std::prelude::*;
use cortex_a::asm::*;

declare_raw_main!(main);

fn main(_: &[u8]) -> Fallible<()> {
    loop {
        wfi()
    }
}
