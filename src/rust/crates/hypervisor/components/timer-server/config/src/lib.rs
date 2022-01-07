#![no_std]

extern crate alloc;

use alloc::vec::Vec;

use serde::{Deserialize, Serialize};

use icecap_config::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub lock: Notification,
    pub dev_vaddr: usize,
    pub irq_handlers: Vec<IRQHandler>,
    pub clients: Vec<Notification>,
    pub endpoints: Vec<Endpoint>,
    pub secondary_threads: Vec<Thread>,
}
