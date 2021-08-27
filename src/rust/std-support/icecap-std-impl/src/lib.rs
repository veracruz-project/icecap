#![no_std]

extern crate core;

mod abort;
mod time;
mod stdio;

// pub mod sel4;

pub use abort::abort;
pub use time::{now, set_now};
pub use stdio::write_to_fd;

pub use icecap_sel4 as sel4;
pub use icecap_runtime as runtime;
pub use icecap_sync as sync;
