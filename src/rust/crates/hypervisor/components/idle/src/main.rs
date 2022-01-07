#![no_std]
#![no_main]

extern crate alloc;

use cortex_a::asm::*;

use icecap_std::prelude::*;

declare_raw_main!(main);

fn main(_: &[u8]) -> Fallible<()> {
    loop {
        wfi()
    }
}
