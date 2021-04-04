use alloc::collections::VecDeque;
use alloc::vec::Vec;

use icecap_sel4::fault::*;
use icecap_failure::*;

use crate::distributor::{
    Distributor, CPU, IRQType,
    WriteAction, ReadAction, PPIAction, SPIAction, SGIAction, AckAction,
};

pub type NodeIndex = usize;
pub type IRQ = usize;

pub trait GICCallbacks {

    fn event(&mut self, node: NodeIndex, target_node: NodeIndex) -> Fallible<()>;

    fn ack(&mut self, node: NodeIndex, irq: IRQ) -> Fallible<()>;

    fn vcpu_inject_irq(&mut self, node: NodeIndex, index: usize, irq: IRQ, priority: usize) -> Fallible<()>;

    fn set_affinity(&mut self, node: NodeIndex, irq: IRQ, target_node: NodeIndex) -> Fallible<()>;

    fn set_priority(&mut self, node: NodeIndex, irq: IRQ, priority: usize) -> Fallible<()>;

    fn set_enabled(&mut self, node: NodeIndex, irq: IRQ, enabled: bool) -> Fallible<()>;
}

pub struct GIC<T> {
    num_nodes: usize,
    callbacks: T,
    dist: Distributor,
    lrs: Vec<LR>,
}

struct LR {
    mirror: [Option<IRQ>; 64],
    overflow: VecDeque<IRQ>,
}

impl<T> GIC<T> {

    pub const DISTRIBUTOR_SIZE: usize = 4096;
}

impl<T: GICCallbacks> GIC<T> {

    pub fn new(num_nodes: usize, callbacks: T) -> Self {
        Self {
            num_nodes,
            callbacks,
            dist: Distributor::new(num_nodes),
            lrs: (0..num_nodes).map(|_| {
                LR {
                    mirror: [None; 64],
                    overflow: VecDeque::new(),
                }
            }).collect(),
        }
    }

    pub fn handle_irq(&mut self, node: NodeIndex, irq: IRQ) -> Fallible<()> {
        todo!()
    }

    pub fn handle_maintenance(&mut self, node: NodeIndex, index: usize) -> Fallible<()> {
        todo!()
    }

    pub fn handle_read(&mut self, node: NodeIndex, offset: usize, width: VMFaultWidth) -> Fallible<VMFaultData> {
        todo!()
    }

    pub fn handle_write(&mut self, node: NodeIndex, offset: usize, data: VMFaultData) -> Fallible<()> {
        todo!()
    }
}
