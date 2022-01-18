#![no_std]

extern crate alloc;

use alloc::vec::Vec;

use serde::{Deserialize, Serialize};

use dyndl_realize_simple_config::*;
use icecap_config::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub lock: Notification,

    pub realizer: ConfigRealizer,

    pub host_bulk_region_start: usize,
    pub host_bulk_region_size: usize,

    pub cnode: CNode,
    pub local: Vec<Local>,
    pub secondary_threads: Vec<Thread>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Local {
    pub endpoint: Endpoint,
    pub reply_slot: Endpoint,
    pub timer_server_client: Endpoint,
    pub event_server_client: Endpoint,
    pub event_server_control: Endpoint,
}
