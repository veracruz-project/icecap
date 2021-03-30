#![no_std]

extern crate alloc;

mod ring_buffer;

pub use ring_buffer::{
    realize_mapped_ring_buffer, realize_mapped_ring_buffer_resume,
    realize_mapped_ring_buffers,
};
