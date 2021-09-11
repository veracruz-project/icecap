#![no_std]
#![feature(format_args_nl)]

extern crate alloc;

mod vmm;
mod psci;

pub use vmm::{
    VMMConfig, VMMNodeConfig,
    VMMExtension, VMMNode,
    IRQMap,
};
