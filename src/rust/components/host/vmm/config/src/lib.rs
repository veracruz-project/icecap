#![no_std]

extern crate alloc;

use alloc::vec::Vec;
use alloc::collections::BTreeMap;
use serde::{Serialize, Deserialize};
use icecap_config::*;
use icecap_event_server_types::events::{HostIn, HostOut};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    // pub con: UnmanagedRingBufferConfig,
    pub cnode: CNode,
    pub gic_lock: Notification,
    pub nodes_lock: Notification,
    pub gic_dist_paddr: usize,
    pub nodes: Vec<Node>,
    pub event_server_client_ep: Vec<Endpoint>,
    pub event_server_control_ep: Vec<Endpoint>,
    pub resource_server_ep: Vec<Endpoint>,
    pub kicks: Vec<KickConfig>,

    pub ppi_map: BTreeMap<usize, HostIn>,
    pub spi_map: BTreeMap<usize, (HostIn, usize)>, // in_index, nid
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Node {
    pub tcb: TCB,
    pub vcpu: VCPU,
    pub thread: Thread,
    pub ep_read: Endpoint,
    pub fault_reply_slot: Endpoint,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum KickConfig {
    Notification(Notification),
    OutIndex(HostOut),
}
