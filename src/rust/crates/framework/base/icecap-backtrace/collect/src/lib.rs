#![no_std]
#![feature(alloc_prelude)]

#[macro_use]
extern crate alloc;

pub use imp::{collect_raw_backtrace, SKIP};

cfg_if::cfg_if! {
    if #[cfg(all(target_os = "icecap", icecap_debug))] {
        mod imp {
            use alloc::prelude::v1::*;
            use core::ffi::c_void;

            use unwinding::abi::*;

            use icecap_backtrace_types::RawStackFrame;

            // NOTE skip:
            pub const SKIP: usize = 4;

            pub fn collect_raw_backtrace() -> (Vec<RawStackFrame>, Option<String>) {
                log::warn!("collecting backtrace");

                struct CallbackData {
                    stack_frames: Vec<RawStackFrame>,
                }
                extern "C" fn callback(
                    unwind_ctx: &mut UnwindContext<'_>,
                    arg: *mut c_void,
                ) -> UnwindReasonCode {
                    let data = unsafe { &mut *(arg as *mut CallbackData) };
                    icecap_sel4::debug_println!(
                        "{:#19x} - <unknown>",
                        _Unwind_GetIP(unwind_ctx)
                    );
                    data.stack_frames.push(RawStackFrame {
                        initial_address: unwinding::abi::_Unwind_GetIP(unwind_ctx) as u64,
                        callsite_address: unwinding::abi::_Unwind_GetIP(unwind_ctx) as u64,
                    });
                    UnwindReasonCode::NO_REASON
                }
                let mut data = CallbackData { stack_frames: vec![] };
                _Unwind_Backtrace(callback, &mut data as *mut _ as _);
                (data.stack_frames, None)
            }
        }
    } else {
        mod imp {
            use alloc::prelude::v1::*;
            use icecap_backtrace_types::RawStackFrame;

            pub const SKIP: usize = 0;

            pub fn collect_raw_backtrace() -> (Vec<RawStackFrame>, Option<String>) {
                let stack_frames = vec![];
                let error = None;
                (stack_frames, error)
            }
        }
    }
}
