#![no_std]

extern crate core;

mod abort;
mod time;
mod stdio;

pub use abort::abort;
pub use stdio::write_to_fd;
pub use time::{now, set_now};

pub use icecap_runtime as runtime;
pub use icecap_sel4 as sel4;
pub use icecap_sync as sync;
pub use icecap_dlmalloc as dlmalloc;
