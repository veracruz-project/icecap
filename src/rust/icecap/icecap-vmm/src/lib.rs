#![no_std]
#![feature(format_args_nl)]

extern crate alloc;

mod vmm;

pub use vmm::{
    VMMConfig, VMMNodeConfig,
    VMMExtension, VMMNode,
    IRQMap,
};
