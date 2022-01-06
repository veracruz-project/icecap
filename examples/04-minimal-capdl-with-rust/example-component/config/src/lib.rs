#![no_std]

extern crate alloc;

use alloc::vec::Vec;
use serde::{Serialize, Deserialize};
use icecap_config::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub lock_nfn: Notification,
    pub primary_thread_ep_cap: Endpoint,
    pub secondary_thread_ep_cap: Endpoint,
    pub secondary_thread: Thread,
    pub foo: Vec<i32>,
}
