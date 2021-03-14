#![no_std]
#![feature(alloc_prelude)]
#![feature(type_ascription)]

#![allow(dead_code)]
#![allow(unused_variables)]
#![allow(unused_imports)]

#[macro_use]
extern crate alloc;

mod chosen;
mod icecap;
mod guest;
mod utils;

pub use chosen::Chosen;
pub use icecap::{RingBuffer, RingBufferSide, RawRingBuffer, Con, Net, Device};
pub use guest::GuestConfig;
pub use utils::mk_range;
