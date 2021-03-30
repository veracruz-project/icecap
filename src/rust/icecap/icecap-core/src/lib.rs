#![no_std]
#![feature(alloc_prelude)]

extern crate alloc;

pub mod prelude;

pub use icecap_sel4 as sel4;
pub use icecap_runtime as runtime;
pub use icecap_sync as sync;
pub use icecap_ring_buffer as ring_buffer;
pub use icecap_config_realize as config_realize;
pub use icecap_config as config;
pub use icecap_backtrace as backtrace;
pub use icecap_failure as failure;
pub use icecap_start as start;

pub use start::declare_main;

// TODO remove
pub use sel4::sys;
