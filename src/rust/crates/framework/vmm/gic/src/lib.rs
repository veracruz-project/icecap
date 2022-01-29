#![no_std]

extern crate alloc;

#[macro_use]
extern crate icecap_failure_derive;

mod gic;
mod distributor;
mod error;

pub use gic::{GICCallbacks, NodeIndex, QualifiedIRQ, GIC, IRQ, PPI, SPI};
