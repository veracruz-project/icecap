#![no_std]

extern crate alloc;

use alloc::vec::Vec;
use serde::{Serialize, Deserialize};
use icecap_sel4_hack::prelude::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub cnode: CNode,
    pub reply_ep: Endpoint,
    pub dev_vaddr: usize,
    pub ep_read: Endpoint,
    pub ep_write: Endpoint,
    pub clients: Vec<Notification>,
    pub irq_thread: Thread,
    pub irq_nfn: Notification,
    pub irq_handler: IRQHandler,
}
