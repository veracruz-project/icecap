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
pub type PPI = usize;
pub type SPI = usize;

pub enum QualifiedIRQ {
    QualifiedPPI { node: NodeIndex, irq: PPI },
    SPI { irq: PPI },
}

pub trait GICCallbacks {

    fn event(&mut self, calling_node: NodeIndex, target_node: NodeIndex) -> Fallible<()>;

    fn ack(&mut self, calling_node: NodeIndex, irq: QualifiedIRQ) -> Fallible<()>;

    fn vcpu_inject_irq(&mut self, calling_node: NodeIndex, target_node: NodeIndex, index: usize, irq: IRQ, priority: usize) -> Fallible<()>;

    fn set_affinity(&mut self, calling_node: NodeIndex, spi: SPI, affinity: NodeIndex) -> Fallible<()>;

    fn set_priority(&mut self, calling_node: NodeIndex, irq: QualifiedIRQ, priority: usize) -> Fallible<()>;

    fn set_enabled(&mut self, calling_node: NodeIndex, irq: QualifiedIRQ, enabled: bool) -> Fallible<()>;
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

    pub fn handle_irq(&mut self, calling_node: NodeIndex, irq: QualifiedIRQ) -> Fallible<()> {
        todo!()
    }

    pub fn handle_maintenance(&mut self, calling_node: NodeIndex, index: usize) -> Fallible<()> {
        todo!()
    }

    pub fn handle_read(&mut self, calling_node: NodeIndex, offset: usize, width: VMFaultWidth) -> Fallible<VMFaultData> {
        todo!()
    }

    pub fn handle_write(&mut self, calling_node: NodeIndex, offset: usize, data: VMFaultData) -> Fallible<()> {
        todo!()
    }
}
