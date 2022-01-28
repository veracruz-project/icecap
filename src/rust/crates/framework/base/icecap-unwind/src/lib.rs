#![no_std]
#![feature(global_asm)]

#[macro_use]
extern crate alloc;

use core::ops::Range;

mod arch;
mod sys;

pub use arch::{
    Unwinder, StackFrames, StackFrame,
    DwarfUnwinder,
};

use sys::{
    find_cfi_sections,
};

#[derive(Debug)]
pub(crate) struct EhRef {
    text: Range<usize>,
    eh_frame_hdr: Range<usize>,
    eh_frame_end: usize,
}
