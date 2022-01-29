#![no_std]
#![feature(alloc_prelude)]
#![feature(type_ascription)]

#[macro_use]
extern crate alloc;

mod chosen;
mod icecap;
mod guest;
mod utils;

pub use chosen::Chosen;
pub use icecap::{Channel, Con, Device, Net, RingBuffer, RingBufferSide};
pub use guest::GuestConfig;
pub use utils::mk_range;
