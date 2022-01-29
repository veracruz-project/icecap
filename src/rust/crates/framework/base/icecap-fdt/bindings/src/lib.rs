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
pub use icecap::{Channel, Con, Device, Net, RingBuffer, RingBufferSide};
pub use realm::RealmConfig;
pub use utils::mk_range;
