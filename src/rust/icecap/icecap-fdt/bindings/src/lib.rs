#![no_std]
#![feature(alloc_prelude)]
#![feature(type_ascription)]

#[macro_use]
extern crate alloc;

mod chosen;
mod icecap;
mod realm;
mod utils;

pub use chosen::Chosen;
pub use icecap::{RingBuffer, RingBufferSide, Channel, Con, Net, Device};
pub use realm::RealmConfig;
pub use utils::mk_range;
