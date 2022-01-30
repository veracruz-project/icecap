#![no_std]
#![no_main]

extern crate alloc;

use icecap_std::prelude::*;
use icecap_start_generic::declare_generic_main;

declare_generic_main!(main);

fn main(_: ()) -> Fallible<()> {
    f();
    Ok(())
}

pub fn f() {
    [()].iter().for_each(g);
}

fn g(_: &()) -> () {
    panic!("test");
}
