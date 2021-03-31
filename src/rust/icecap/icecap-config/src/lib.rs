#![no_std]

use serde::{Serialize, Deserialize};

pub use icecap_config_sys::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RingBufferConfig {
    pub wait: Notification,
    pub read: RingBufferSideConfig,
    pub write: RingBufferSideConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RingBufferSideConfig {
    pub signal: Notification,
    pub size: usize,
    pub ctrl: usize,
    pub data: usize,
}
