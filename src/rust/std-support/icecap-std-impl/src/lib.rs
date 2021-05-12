#![no_std]
#![feature(const_fn)]

extern crate core;

mod abort;
mod time;
mod env;
mod supervisor;

pub mod sel4;

pub use abort::abort;
pub use time::{now, set_now};
pub use env::supervisor;
pub use supervisor::Supervisor;

pub mod deps {
    pub use icecap_sel4 as sel4;
    pub use icecap_sync as sync;
}
