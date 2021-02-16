#![no_std]
#![feature(alloc_prelude)]

#[macro_use]
extern crate alloc;

#[cfg(target_os = "icecap")]
use icecap_failure as failure;
#[cfg(not(target_os = "icecap"))]
use failure;

mod types;
mod read;
mod write;
mod debug;
pub mod bindings; // TODO do these need to be in this crate?

pub use types::{DeviceTree, ReserveEntry, Node, Value};

fn align_up(x: usize, n: usize) -> usize {
    match x {
        0 => 0,
        _ => ((x - 1) | (n - 1)) + 1,
    }
}
