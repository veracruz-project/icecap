use alloc::vec::Vec;
use icecap_config::*;
use crate::{RingBuffer, RingBufferSide};

impl RingBuffer {

    pub fn realize(config: &RingBufferConfig) -> Self {
        Self::new(
            RingBufferSide::new(
                config.read.size,
                config.read.signal,
                config.read.ctrl,
                config.read.data as *const u8,
            ),
            RingBufferSide::new(
                config.write.size,
                config.write.signal,
                config.write.ctrl,
                config.write.data as *mut u8,
            ),
        )
    }

    pub fn realize_resume(config: &RingBufferConfig) -> Self {
        RingBuffer::resume(
            RingBufferSide::new(
                config.read.size,
                config.read.signal,
                config.read.ctrl,
                config.read.data as *const u8,
            ),
            RingBufferSide::new(
                config.write.size,
                config.write.signal,
                config.write.ctrl,
                config.write.data as *mut u8,
            ),
        )
    }
}