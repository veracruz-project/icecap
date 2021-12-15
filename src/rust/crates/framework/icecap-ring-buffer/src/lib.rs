#![no_std]
#![feature(stdsimd)]
#![feature(core_intrinsics)]

#[macro_use]
extern crate alloc;

mod ring_buffer;
mod buffered_ring_buffer;
mod realize;

pub use ring_buffer::{Kick, RingBuffer, RingBufferSide, PacketRingBuffer, RingBufferPointer};
pub use buffered_ring_buffer::{BufferedRingBuffer, BufferedPacketRingBuffer};
