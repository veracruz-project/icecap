#![no_std]
#![feature(llvm_asm)]
#![feature(format_args_nl)]
#![allow(unused_variables)]
#![allow(dead_code)]

extern crate alloc;

mod vmm;
mod asm;

pub use vmm::*;
