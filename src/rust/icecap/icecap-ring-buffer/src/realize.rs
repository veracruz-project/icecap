use alloc::vec::Vec;
use alloc::boxed::Box;
use icecap_config::*;
use crate::{RingBuffer, RingBufferSide, RingBufferPointer, Kick};

fn mk_kick(nfn: Notification) -> Kick {
    Box::new(move || nfn.signal())
}

fn mk_kicks(kicks: &RingBufferKicksConfig<Notification>) -> RingBufferKicksConfig<Kick> {
    RingBufferKicksConfig {
        read: mk_kick(kicks.read),
        write: mk_kick(kicks.write),
    }
}

impl RingBuffer {

    pub fn realize(config: &RingBufferConfig, kicks: RingBufferKicksConfig<Kick>) -> Self {
        Self::new(
            RingBufferSide::realize(&config.read, kicks.read),
            RingBufferSide::realize(&config.write, kicks.write),
        )
    }

    pub fn realize_resume(config: &RingBufferConfig, kicks: RingBufferKicksConfig<Kick>) -> Self {
        Self::resume(
            RingBufferSide::realize(&config.read, kicks.read),
            RingBufferSide::realize(&config.write, kicks.write),
        )
    }

    pub fn realize_unmanaged(config: &UnmanagedRingBufferConfig) -> Self {
        Self::realize(&config.ring_buffer, mk_kicks(&config.kicks))
    }

    pub fn realize_resume_unmanaged(config: &UnmanagedRingBufferConfig) -> Self {
        Self::realize_resume(&config.ring_buffer, mk_kicks(&config.kicks))
    }
}

impl<T: RingBufferPointer> RingBufferSide<T> {

    pub fn realize(config: &RingBufferSideConfig, kick: Kick) -> Self {
        Self::new(
            config.size,
            config.ctrl,
            T::from_address(config.data),
            kick,
        )
    }
}
