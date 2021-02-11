#![feature(panic_info_message)]
#![feature(rustc_private)]

use std::sync::{Arc, Mutex};
use std::alloc::{Layout};
use std::alloc::GlobalAlloc;

use icecap_core::prelude::*;
use icecap_core::backtrace::Backtrace;

pub fn early_init() {
    set_panic()
}

pub fn set_panic() {
    std::panic::set_hook(Box::new(|info| {
        print!("panicked");
        if let Some(args) = info.message() {
            print!(" with '{}'", args);
        }
        if let Some(loc) = info.location() {
            print!(" at {} {},{}", loc.file(), loc.line(), loc.column());
        }
        print!("\n");

        println!("stack backtrace:");
        println!("    {}", Backtrace::new().raw.serialize());
        println!("");

        print!("panic info: {:?}", info);
    }));
}
