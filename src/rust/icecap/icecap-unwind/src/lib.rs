#![no_std]
#![feature(global_asm)]

#[macro_use]
extern crate alloc;

mod arch;
mod sys;

use core::ops::Range;

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
