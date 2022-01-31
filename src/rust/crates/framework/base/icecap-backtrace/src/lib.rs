#![no_std]
#![feature(alloc_prelude)]

extern crate alloc;

use alloc::prelude::v1::*;

use icecap_backtrace_collect::collect_raw_backtrace;
use icecap_backtrace_types::RawBacktrace;
use icecap_runtime::image_path;

#[derive(Debug, Clone)]
pub struct Backtrace {
    pub raw: RawBacktrace,
}

impl Backtrace {
    pub fn new() -> Self {
        let (stack_frames, error) = collect_raw_backtrace();
        Self {
            raw: RawBacktrace {
                path: image_path().map(|r| r.unwrap().to_string()),
                stack_frames,
                error,
            },
        }
    }
}
