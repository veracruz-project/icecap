#![no_std]
#![feature(alloc_error_handler)]
#![feature(lang_items)]
#![feature(panic_info_message)]

extern crate alloc;

pub use icecap_core::*;

mod allocator;
mod panic;

pub mod fmt;
pub mod prelude;
