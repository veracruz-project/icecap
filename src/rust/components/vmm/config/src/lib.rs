#![no_std]

extern crate alloc;

use alloc::vec::Vec;
use serde::{Serialize, Deserialize};
use icecap_config_common::{DescTimerClient, DescMappedRingBuffer};
use icecap_sel4_hack::prelude::*;

pub type IRQ = usize;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub cnode: CNode,

    pub con: DescMappedRingBuffer,
    pub timer: DescTimerClient,
    pub timer_thread: Thread,

    pub gic_dist_vaddr: usize,
    pub gic_dist_paddr: usize,

    pub real_virtual_timer_irq: IRQ,
    pub virtual_timer_irq: IRQ,
    pub virtual_irqs: Vec<IRQGroup<IRQ>>,
    pub passthru_irqs: Vec<IRQGroup<PassthruIRQ>>,

    pub ep_write: Endpoint,
    pub ep_read: Endpoint,
    pub reply_ep: Endpoint,
    pub tcb: TCB,
    pub vcpu: VCPU,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IRQGroup<T> {
    pub nfn: Notification,
    pub thread: Thread,
    // always length 64, but serde doesn't provide instances for statically sized arrays of length > 32
    pub irqs: Vec<Option<T>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PassthruIRQ {
    pub irq: IRQ,
    pub handler: IRQHandler,
}