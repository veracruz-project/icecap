#![no_std]

extern crate alloc;

use alloc::vec::Vec;

use serde::{Deserialize, Serialize};

use icecap_config::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub lock: Notification,

    pub event: Notification,
    pub event_server_endpoint: Endpoint,
    pub event_server_bitfield: usize,

    pub net_rb: RingBufferConfig,

    pub passthru: Vec<u8>,
}
