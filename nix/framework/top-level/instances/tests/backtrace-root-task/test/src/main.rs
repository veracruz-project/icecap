#![no_std]
#![no_main]

extern crate alloc;

use icecap_std::prelude::*;
use icecap_std::sel4::BootInfo;

declare_root_main!(main);

fn main(_: BootInfo) -> Fallible<()> {
    f();
    Ok(())
}

pub fn f() {
    [()].iter().for_each(g);
}

fn g(_: &()) -> () {
    panic!("test");
}
