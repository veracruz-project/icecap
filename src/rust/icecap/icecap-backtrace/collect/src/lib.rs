#![no_std]
#![feature(alloc_prelude)]

#[macro_use]
extern crate alloc;

use alloc::prelude::v1::*;
use fallible_iterator::FallibleIterator;
use icecap_backtrace_types::RawStackFrame;
use icecap_unwind::{Unwinder, DwarfUnwinder};

pub const SKIP: usize = 4;
// NOTE skip:
//     unwind::Unwinder::trace
//     collect_raw_backtrace
//     Backtrace::raw
//     Backtrace::new_skip

pub fn collect_raw_backtrace() -> (Vec<RawStackFrame>, Option<String>) {
    log::warn!("collecting backtrace");
    let mut stack_frames = vec![];
    let mut error = None;
    DwarfUnwinder::default().trace(|frames| {
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
    (stack_frames, error)
}
