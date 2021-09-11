#![no_std]
#![feature(alloc_prelude)]

extern crate alloc;

use alloc::prelude::v1::*;
use icecap_runtime::image_path;
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
                path: image_path().unwrap().to_string(),
                skip,
                stack_frames,
                error,
            },
        }
    }
}
