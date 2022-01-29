#![no_std]

extern crate alloc;

use alloc::collections::BTreeMap;
use alloc::vec::Vec;

use serde::{Deserialize, Serialize};

use hypervisor_event_server_types::events::HostIn;
use icecap_config::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub cnode: CNode,
    pub gic_lock: Notification,
    pub nodes_lock: Notification,
    pub gic_dist_paddr: usize,
    pub nodes: Vec<Node>,
    pub event_server_client_ep: Vec<Endpoint>,
    pub event_server_control_ep: Vec<Endpoint>,
    pub resource_server_ep: Vec<Endpoint>,
    pub benchmark_server_ep: Endpoint,

    pub ppi_map: BTreeMap<usize, (HostIn, bool)>, // in_index, must_ack
    pub spi_map: BTreeMap<usize, (HostIn, usize, bool)>, // in_index, nid, must_ack

    pub log_buffer: LargePage,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Node {
    pub tcb: TCB,
    pub vcpu: VCPU,
    pub thread: Thread,
    pub ep_read: Endpoint,
    pub fault_reply_slot: Endpoint,
    pub event_server_bitfield: usize,
}
