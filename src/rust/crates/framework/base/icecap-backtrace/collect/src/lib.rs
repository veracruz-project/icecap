#![no_std]
#![feature(alloc_prelude)]

#[macro_use]
extern crate alloc;

use alloc::prelude::v1::*;
use icecap_backtrace_types::{RawStackFrame, Error};

cfg_if::cfg_if! {
    if #[cfg(all(target_os = "icecap", icecap_debug))] {

        use core::ffi::c_void;
        use unwinding::abi::*;

        pub fn collect_raw_backtrace() -> (Vec<RawStackFrame>, Option<Error>) {
            log::warn!("collecting backtrace");

            struct CallbackData {
                stack_frames: Vec<RawStackFrame>,
            }

            extern "C" fn callback(
                unwind_ctx: &mut UnwindContext<'_>,
                arg: *mut c_void,
            ) -> UnwindReasonCode {
                let data = unsafe { &mut *(arg as *mut CallbackData) };
                let ip = _Unwind_GetIP(unwind_ctx) as usize;
                data.stack_frames.push(RawStackFrame {
                    ip,
                });
                UnwindReasonCode::NO_REASON
            }

            let mut data = CallbackData { stack_frames: vec![] };
            _Unwind_Backtrace(callback, &mut data as *mut _ as _);
            (data.stack_frames, None)
        }

    } else {

        pub fn collect_raw_backtrace() -> (Vec<RawStackFrame>, Option<Error>) {
            (vec![], None)
        }

    }
}
