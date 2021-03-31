#![no_std]

extern crate alloc;

use alloc::vec::Vec;
use serde::{Serialize, Deserialize};

use icecap_config::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub cnode: CNode,
    pub reply_ep: Endpoint,
    pub dev_vaddr: usize,
    pub ep: Endpoint,
    pub event_server: Endpoint,
    pub host_client: Client,
    pub realm_clients: Vec<Client>,
    pub irq_nfn: Notification,
    pub irq_handler: IRQHandler,
    pub irq_thread: Thread,
    pub timer_ep_write: Endpoint,
    pub timer_wait: Notification,
    pub timer_thread: Thread,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Client {
    pub thread: Thread,
    pub wait: Notification,
    pub ring_buffer: RingBufferConfig,
}
