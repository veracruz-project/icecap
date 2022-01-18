#![no_std]

extern crate alloc;

use alloc::vec::Vec;
use icecap_config::*;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub lock_nfn: Notification,
    pub barrier_nfn: Notification,
    pub secondary_thread: Thread,
    pub foo: Vec<i32>,
}
