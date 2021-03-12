#![no_std]

extern crate alloc;

mod interfaces;

pub use interfaces::{
    realize_timer_client,
    realize_mapped_ring_buffer, realize_mapped_ring_buffer_resume,
    realize_mapped_ring_buffers,
};
