use alloc::boxed::Box;

use icecap_config::*;

use crate::{Kick, RingBuffer, RingBufferPointer, RingBufferSide};

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
    pub fn from_config(config: &RingBufferConfig, kicks: RingBufferKicksConfig<Kick>) -> Self {
        Self::new(
            RingBufferSide::from_config(&config.read, kicks.read),
            RingBufferSide::from_config(&config.write, kicks.write),
        )
    }

    pub fn resume_from_config(config: &RingBufferConfig, kicks: RingBufferKicksConfig<Kick>) -> Self {
        Self::resume(
            RingBufferSide::from_config(&config.read, kicks.read),
            RingBufferSide::from_config(&config.write, kicks.write),
        )
    }

    pub fn unmanaged_from_config(config: &UnmanagedRingBufferConfig) -> Self {
        Self::from_config(&config.ring_buffer, mk_kicks(&config.kicks))
    }

    pub fn resume_unmanaged_from_config(config: &UnmanagedRingBufferConfig) -> Self {
        Self::resume_from_config(&config.ring_buffer, mk_kicks(&config.kicks))
    }
}

impl<T: RingBufferPointer> RingBufferSide<T> {
    pub fn from_config(config: &RingBufferSideConfig, kick: Kick) -> Self {
        Self::new(config.size, config.ctrl, T::from_address(config.data), kick)
    }
}
