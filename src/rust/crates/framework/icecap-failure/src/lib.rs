#![no_std]
#![feature(allocator_api)]
#![feature(never_type)]

extern crate alloc;

mod as_fail;
mod backtrace;
mod context;
mod error;
mod error_message;
mod fail;
mod impls;
mod macros;
mod result_ext;

pub use as_fail::AsFail;
pub use backtrace::Backtrace;
pub use context::Context;
pub use error::Error;
pub use error_message::{err_msg, err_msg_as_error};
pub use fail::{Fail, Causes};
pub use result_ext::ResultExt;

pub use icecap_failure_derive::*;

/// A common result with an `Error`.
pub type Fallible<T> = Result<T, Error>;
