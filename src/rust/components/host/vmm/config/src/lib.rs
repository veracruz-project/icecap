#![no_std]

extern crate alloc;

use alloc::vec::Vec;
use serde::{Serialize, Deserialize};
use icecap_config::*;

pub type IRQ = usize;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub con: RingBufferConfig,
    pub cnode: CNode,
    pub gic_lock: Notification,
    pub nodes_lock: Notification,
    pub virtual_irqs: Vec<IRQGroup<IRQ>>,
    pub passthru_irqs: Vec<IRQGroup<PassthruIRQ>>,
    pub gic_dist_paddr: usize,
    pub nodes: Vec<Node>,
    pub resource_server_ep_write: Endpoint,
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IRQGroup<T> {
    pub nfn: Notification,
    pub thread: Thread,
    // always length 64, but serde doesn't provide instances for statically sized arrays of length > 32
    pub bits: Vec<Option<T>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PassthruIRQ {
    pub irq: IRQ,
    pub handler: IRQHandler,
}
