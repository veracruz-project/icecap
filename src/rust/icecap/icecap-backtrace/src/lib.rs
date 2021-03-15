#![no_std]
#![feature(alloc_prelude)]

#[macro_use]
extern crate alloc;

use alloc::prelude::v1::*;
use alloc::str;
use icecap_backtrace_types::RawBacktrace;
use icecap_backtrace_collect::{collect_raw_backtrace, SKIP};

#[derive(Debug, Clone)]
pub struct Backtrace {
    pub raw: RawBacktrace,
}

impl Backtrace {
    pub fn new() -> Self {
        Self::new_skip(1)
    }

    pub fn new_skip(skip: usize) -> Self {
        Self::raw(SKIP + skip)
    }

    pub fn raw(skip: usize) -> Self {
        let (stack_frames, error) = collect_raw_backtrace();
        Self {
            raw: RawBacktrace {
                path: get_image_path(),
                skip,
                stack_frames,
                error,
            },
        }
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
