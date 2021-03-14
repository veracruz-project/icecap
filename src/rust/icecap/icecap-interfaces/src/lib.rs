#![no_std]

#![feature(stdsimd)]
#![feature(core_intrinsics)]
#![allow(unused_imports)]

#[macro_use]
extern crate alloc;

mod ring_buffer;
mod timer;
mod con;
mod net;

pub use ring_buffer::{RingBuffer, RingBufferSide, PacketRingBuffer};
pub use timer::Timer;
pub use con::ConDriver;
pub use net::NetDriver;
