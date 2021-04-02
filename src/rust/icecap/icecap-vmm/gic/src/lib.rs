#![no_std]
#![feature(llvm_asm)]
#![feature(exclusive_range_pattern)]
#![feature(type_ascription)]
#![feature(format_args_nl)]
#![allow(dead_code)]

extern crate alloc;

mod gic;
mod distributor;

pub use gic::{
    GIC, GICCallbacks, NodeIndex, IRQ,
};
