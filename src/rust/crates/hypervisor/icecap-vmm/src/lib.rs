#![no_std]

extern crate alloc;

mod vmm;
mod psci;

pub use vmm::{
    VMMConfig, VMMNodeConfig,
    VMMExtension, VMMNode,
    IRQMap,
};
