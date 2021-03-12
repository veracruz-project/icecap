#![no_std]

extern crate alloc;

use alloc::vec::Vec;
use serde::{Serialize, Deserialize};

use icecap_config_common::{DescTimerClient, DescMappedRingBuffer};
use icecap_config_common::{sel4::prelude::*, Thread};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub cnode: CNode,
    pub reply_ep: Endpoint,
    pub dev_vaddr: usize,
    pub ep: Endpoint,
    pub clients: Vec<Client>,
    pub irq_nfn: Notification,
    pub irq_handler: IRQHandler,
    pub irq_thread: Thread,
    pub timer: DescTimerClient,
    pub timer_thread: Thread,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Client {
    pub thread: Thread,
    pub ring_buffer: DescMappedRingBuffer,
}
