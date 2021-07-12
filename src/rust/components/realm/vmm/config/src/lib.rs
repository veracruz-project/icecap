#![no_std]

extern crate alloc;

use alloc::vec::Vec;
use alloc::collections::BTreeMap;
use serde::{Serialize, Deserialize};
use icecap_config::*;
use icecap_event_server_types::events::HostIn;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    // pub con: UnmanagedRingBufferConfig,
    pub cnode: CNode,
    pub gic_lock: Notification,
    pub nodes_lock: Notification,
    pub gic_dist_paddr: usize,
    pub nodes: Vec<Node>,
    pub event_server_client_ep: Vec<Endpoint>,

    pub ppi_map: BTreeMap<usize, HostIn>,
    pub spi_map: BTreeMap<usize, (HostIn, usize)>, // in_index, nid
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Node {
    pub tcb: TCB,
    pub vcpu: VCPU,
    pub thread: Thread,
    pub ep_read: Endpoint,
    pub ep_write: Endpoint,
    pub fault_reply_slot: Endpoint,
}
