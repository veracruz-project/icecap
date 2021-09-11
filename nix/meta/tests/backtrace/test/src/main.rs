#![no_std]
#![no_main]
#![feature(alloc_prelude)]
#![feature(array_value_iter)]
#![feature(format_args_nl)]
#![feature(c_variadic)]
#![feature(type_ascription)]
#![feature(new_uninit)]
#![feature(slice_ptr_range)]
#![feature(llvm_asm)]
#![feature(const_mut_refs)]
#![allow(dead_code)]
#![allow(unused_comparisons)]
#![allow(unused_imports)]
#![allow(unused_variables)]

extern crate alloc;

use serde::{Serialize, Deserialize};

use icecap_std::prelude::*;
use icecap_start_generic::declare_generic_main;

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    test: String,
}

fn main(config: Config) -> Fallible<()> {
    debug_println!("test: {}", config.test);
    f();
    Ok(())
}

pub fn f() {
    let mut x = alloc::vec::Vec::new();
    x.push(());
    x.iter().for_each(g);
}

fn g(_: &()) -> () {
    panic!("test")
}
