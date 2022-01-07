#![no_std]

use serde::{Deserialize, Serialize};

pub use icecap_config_sys::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RingBufferConfig {
    pub read: RingBufferSideConfig,
    pub write: RingBufferSideConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RingBufferSideConfig {
    pub size: usize,
    pub ctrl: usize,
    pub data: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RingBufferKicksConfig<T> {
    pub read: T,
    pub write: T,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UnmanagedRingBufferConfig {
    pub ring_buffer: RingBufferConfig,
    pub kicks: RingBufferKicksConfig<Notification>,
}
