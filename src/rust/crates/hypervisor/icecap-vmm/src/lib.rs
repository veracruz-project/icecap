#![no_std]

extern crate alloc;

mod vmm;

pub use vmm::{IRQMap, VMMConfig, VMMExtension, VMMNode, VMMNodeConfig};
