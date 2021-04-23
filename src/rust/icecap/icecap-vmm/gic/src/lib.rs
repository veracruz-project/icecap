#![no_std]
#![feature(llvm_asm)]
#![feature(exclusive_range_pattern)]
#![feature(type_ascription)]
#![feature(format_args_nl)]
#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_variables)]
#![allow(unreachable_patterns)]

extern crate alloc;

#[macro_use]
extern crate icecap_failure_derive;

mod gic;
mod distributor;
mod error;

pub use gic::{
    GIC, GICCallbacks, NodeIndex, IRQ, PPI, SPI, QualifiedIRQ,
};
