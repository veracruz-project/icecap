#![no_std]

#![feature(stdsimd)]
#![feature(core_intrinsics)]
#![allow(unused_imports)]

#[macro_use]
extern crate alloc;

mod ring_buffer;
mod buffered_ring_buffer;
mod realize;

pub use ring_buffer::{RingBuffer, RingBufferSide, PacketRingBuffer};
pub use buffered_ring_buffer::{BufferedRingBuffer, BufferedPacketRingBuffer};
