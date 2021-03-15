#![no_std]
#![feature(alloc_prelude)]

#[macro_use]
extern crate alloc;

use alloc::prelude::v1::*;
use icecap_backtrace_types::RawStackFrame;

pub const SKIP: usize = 0;

pub fn collect_raw_backtrace() -> (Vec<RawStackFrame>, Option<String>) {
    let stack_frames = vec![];
    let error = None;
    (stack_frames, error)
}
