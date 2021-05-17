#![no_std]
#![feature(alloc_error_handler)]
#![feature(alloc_prelude)]
#![feature(format_args_nl)]
#![feature(lang_items)]
#![feature(panic_info_message)]

extern crate alloc;

mod allocator;
mod panic;

#[path = "fmt.rs"]
pub mod _fmt;

pub use icecap_core::*;

pub mod prelude;

pub use _fmt::{set_print, flush_print};
