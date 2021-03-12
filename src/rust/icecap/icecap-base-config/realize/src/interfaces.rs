use alloc::vec::Vec;

use icecap_interfaces::{RingBuffer, RingBufferSide, Timer};
use icecap_base_config::*;

pub fn realize_timer_client(desc: &DescTimerClient) -> Timer {
    Timer::new(desc.ep_write)
}

pub fn realize_mapped_ring_buffer(desc: &DescMappedRingBuffer) -> RingBuffer {
    RingBuffer::new(
        RingBufferSide::new(
            desc.read.size,
            desc.read.signal,
            desc.read.ctrl,
            desc.read.data as *const u8,
        ),
        RingBufferSide::new(
            desc.write.size,
            desc.write.signal,
            desc.write.ctrl,
            desc.write.data as *mut u8,
        ),
    )
}

pub fn realize_mapped_ring_buffer_resume(desc: &DescMappedRingBuffer) -> RingBuffer {
    RingBuffer::resume(
        RingBufferSide::new(
            desc.read.size,
            desc.read.signal,
            desc.read.ctrl,
            desc.read.data as *const u8,
        ),
        RingBufferSide::new(
            desc.write.size,
            desc.write.signal,
            desc.write.ctrl,
            desc.write.data as *mut u8,
        ),
    )
}

pub fn realize_mapped_ring_buffers(desc: &DescMappedRingBuffers) -> Vec<RingBuffer> {
    desc.iter().map(realize_mapped_ring_buffer).collect()
}
