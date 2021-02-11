#![no_std]
#![feature(global_asm)]

#[macro_use] extern crate alloc;

use alloc::string::{String, ToString};
use alloc::str;
use alloc::vec;
use fallible_iterator::FallibleIterator;
pub use icecap_backtrace_types::{RawBacktrace, RawStackFrame};
use crate::unwind::Unwinder;

mod unwind;

#[derive(Debug, Clone)]
pub struct Backtrace {
    pub raw: RawBacktrace,
}

const SKIP: usize = 4;
// NOTE skip:
//     unwind::Unwinder::trace
//     collect_raw_backtrace
//     Backtrace::raw
//     Backtrace::new_skip


impl Backtrace {
    pub fn new() -> Self {
        Self::new_skip(1)
    }

    pub fn new_skip(skip: usize) -> Self {
        Self::raw(SKIP + skip)
    }

    pub fn raw(skip: usize) -> Self {
        Self {
            raw: collect_raw_backtrace(skip),
        }
    }
}

fn collect_raw_backtrace(skip: usize) -> RawBacktrace {
    log::warn!("collecting backtrace");
    let mut stack_frames = vec![];
    let mut error = None;
    unwind::DwarfUnwinder::default().trace(|frames| {
        frames.for_each(|frame| {
            stack_frames.push(RawStackFrame {
                initial_address: frame.initial_address,
                callsite_address: frame.caller,
            });
            Ok(())
        }).err().map(|err| {
            error = Some(String::from(err.description()));
        });
    });
    RawBacktrace {
        path: get_image_path(),
        skip,
        stack_frames,
        error,
    }
}

extern "C" {
    static icecap_runtime_image_path: *const u8;
}

fn get_image_path() -> String {
    let mut v = vec![];
    let mut p = unsafe { icecap_runtime_image_path };
    loop {
        match unsafe { *p } {
            0 => break,
            c => v.push(c),
        }
        p = unsafe { p.offset(1) };
    }
    str::from_utf8(&v).unwrap().to_string()
}
