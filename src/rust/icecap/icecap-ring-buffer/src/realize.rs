use alloc::vec::Vec;
use alloc::boxed::Box;
use icecap_config::*;
use crate::{RingBuffer, RingBufferSide};

fn mk_kick(nfn: Notification) -> Box<dyn Fn()> {
    Box::new(move || nfn.signal())
}

impl RingBuffer {

    pub fn realize(config: &RingBufferConfig) -> Self {
        Self::new(
            RingBufferSide::new(
                config.read.size,
                config.read.ctrl,
                config.read.data as *const u8,
                mk_kick(config.read.signal),
            ),
            RingBufferSide::new(
                config.write.size,
                config.write.ctrl,
                config.write.data as *mut u8,
                mk_kick(config.write.signal),
            ),
        )
    }

    pub fn realize_resume(config: &RingBufferConfig) -> Self {
        RingBuffer::resume(
            RingBufferSide::new(
                config.read.size,
                config.read.ctrl,
                config.read.data as *const u8,
                mk_kick(config.read.signal),
            ),
            RingBufferSide::new(
                config.write.size,
                config.write.ctrl,
                config.write.data as *mut u8,
                mk_kick(config.write.signal),
            ),
        )
    }
}
