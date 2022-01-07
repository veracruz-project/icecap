#![no_std]

extern crate alloc;

mod vmm;
mod psci;

pub use vmm::{IRQMap, VMMConfig, VMMExtension, VMMNode, VMMNodeConfig};
