#![no_std]
#![feature(stdsimd)]
#![feature(core_intrinsics)]

#[macro_use]
extern crate alloc;

mod ring_buffer;
mod buffered_ring_buffer;
mod realize;

pub use buffered_ring_buffer::{BufferedPacketRingBuffer, BufferedRingBuffer};
pub use ring_buffer::{Kick, PacketRingBuffer, RingBuffer, RingBufferPointer, RingBufferSide};
