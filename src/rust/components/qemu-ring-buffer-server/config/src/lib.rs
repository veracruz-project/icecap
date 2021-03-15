#![no_std]

extern crate alloc;

use serde::{Serialize, Deserialize};

use icecap_config::DescMappedRingBuffer;
use icecap_config::sel4::prelude::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub ready_signal: Notification,
    pub wait: Notification, // [0:1] (client wait) [2] (irq)
    pub client_signal: Notification, // badged with 0b11, for both rx and tx
    pub irq_handler: IRQHandler,
    pub dev_vaddr: usize,
    pub layout: Layout,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Layout {
    pub read: LayoutSide,
    pub write: LayoutSide,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LayoutSide {
    pub ctrl: usize,
    pub data: usize,
    pub size: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Client {
    pub ready_wait: Option<Notification>,
    pub rb: DescMappedRingBuffer,
}
