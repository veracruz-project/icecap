#![no_std]
#![feature(format_args_nl)]

extern crate alloc;

#[macro_use]
extern crate icecap_failure_derive;

mod gic;
mod distributor;
mod error;

pub use gic::{
    GIC, GICCallbacks, NodeIndex, IRQ, PPI, SPI, QualifiedIRQ,
};
