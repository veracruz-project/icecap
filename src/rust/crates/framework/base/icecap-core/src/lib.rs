#![no_std]
#![feature(alloc_prelude)]
#![feature(custom_inner_attributes)]
#![rustfmt::skip]

extern crate alloc;

pub mod prelude;

pub use icecap_sel4 as sel4;
pub use icecap_runtime as runtime;
pub use icecap_sync as sync;
pub use icecap_ring_buffer as ring_buffer;
pub use icecap_rpc as rpc;
pub use icecap_backtrace as backtrace;
pub use icecap_failure as failure;
pub use icecap_logger as logger;
pub use icecap_start as start;
pub use icecap_config as config;

pub use icecap_start::{declare_main, declare_root_main, declare_raw_main};
