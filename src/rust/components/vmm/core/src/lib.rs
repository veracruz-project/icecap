#![no_std]
#![feature(llvm_asm)]
#![feature(exclusive_range_pattern)]
#![feature(type_ascription)]
#![feature(format_args_nl)]
#![allow(dead_code)]

extern crate alloc;

mod run;
mod gic;
mod asm;
mod event;
mod biterate;

pub use run::{run, BADGE_EXTERNAL, BADGE_VM, Mailbox};
pub use event::{Event, RingBufferEvent};
pub use gic::{IRQ, CPU, IRQType, Distributor};
pub use biterate::biterate;
