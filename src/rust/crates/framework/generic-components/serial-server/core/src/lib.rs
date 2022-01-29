#![no_std]
#![no_main]

extern crate alloc;

mod fmt;
mod color;
mod plat;
mod event;
mod server;

pub type ClientId = usize;

pub use plat::plat_init_device;
pub use event::Event;
pub use server::run;
