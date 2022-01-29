#![no_std]

extern crate alloc;

use alloc::collections::BTreeMap;
use alloc::vec::Vec;

use serde::{Deserialize, Serialize};

use icecap_config::*;
use hypervisor_event_server_types::events::{RealmIn, RealmOut};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub cnode: CNode,
    pub gic_lock: Notification,
    pub nodes_lock: Notification,
    pub gic_dist_paddr: usize,
    pub nodes: Vec<Node>,
    pub event_server_client_ep: Vec<Endpoint>,

    pub ppi_map: BTreeMap<usize, (RealmIn, bool)>,
    pub spi_map: BTreeMap<usize, (RealmIn, usize, bool)>, // in_index, nid
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum KickConfig {
    Notification(Notification),
    OutIndex(RealmOut),
}
