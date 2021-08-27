use core::convert::TryFrom;
use alloc::collections::VecDeque;
use alloc::vec::Vec;

use icecap_sel4::prelude::*; // TODO: Remove.  Just for debug.

use icecap_sel4::fault::*;
use icecap_failure::*;

use biterate::biterate;

use crate::distributor::{
    Distributor, CPU, IRQType, WriteAction, ReadAction,
};

use crate::error::{
    IRQError, IRQErrorType,
};

pub type NodeIndex = usize;
pub type IRQ = usize;
pub type PPI = usize;
pub type SPI = usize;

const NUM_LRS: usize = 4;

#[derive(Debug)]
pub enum QualifiedIRQ {
    QualifiedPPI { node: NodeIndex, irq: PPI },
    SPI { irq: SPI },
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
    mirror: [Option<IRQ>; NUM_LRS],
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
                    mirror: [None; NUM_LRS],
                    overflow: VecDeque::new(),
                }
            }).collect(),
        }
    }

    // HACK?
    pub fn callbacks(&self) -> &T {
        &self.callbacks
    }

    /// Handles externally-generated PPIs and SPIs.
    /// SGIs are handled within the GIC and are initiated by writes to the GIC Distributor.
    pub fn handle_irq(&mut self, calling_node: NodeIndex, irq: QualifiedIRQ) -> Fallible<()> {
        match irq {
            QualifiedIRQ::QualifiedPPI { node, irq }=> {
                let target_node = node;
                self.forward_irq(calling_node, target_node, irq)?;
            }
            QualifiedIRQ::SPI { irq }=> {
                // For SPIs, we need to pick one of the targets.
                // Select the caller node if it's a target, otherwise the first returned from the
                // Distributor's `get_spi_targets()` method.
                if self.dist.is_target(irq, calling_node) {
                    self.forward_irq(calling_node, calling_node, irq)?;
                } else {
                    let targets = self.dist.get_spi_targets(irq);
                    for target_node in biterate(targets) {
                        self.forward_irq(calling_node, usize::try_from(target_node)?, irq)?;
                        break;
                    }
                }
            }
        }

        Ok(())
    }

    /// Handles a VGICMaintenance fault.
    ///
    /// Nominally, this results from the vCPU attempting to end a PPI or SPI.
    pub fn handle_maintenance(&mut self, node: NodeIndex, index: usize) -> Fallible<()> {
        let irq = self.lrs[node].mirror[index].unwrap();
        self.lrs[node].mirror[index] = None;

        // Update Distributor state.
        self.dist.ack(irq, node)?;

        // Handle ack callbacks for PPIs and SPIs.
        if irq >= 16 && irq < 32 {
            let qualified_irq = QualifiedIRQ::QualifiedPPI { node, irq };
            self.callbacks.ack(node, qualified_irq)?;
        } else {
            let qualified_irq = QualifiedIRQ::SPI { irq };
            self.callbacks.ack(node, qualified_irq)?;
        }

        if let Some(irq) = self.lrs[node].overflow.pop_front() {
            let calling_node = node;
            let target_node = node;
            self.inject_irq(calling_node, target_node, index, irq)?;
        }

        Ok(())
    }

    /// Handles reads from the GIC Distributor and returns the requested data.
    pub fn handle_read(&mut self, node: NodeIndex, offset: usize, width: VMFaultWidth) -> Fallible<VMFaultData> {
        let (data, read_action) = self.dist.handle_read(offset, node, width)?;
		match read_action {
			ReadAction::NoAction => {}
			_ => panic!("Unexpected ReadAction")
		};
        Ok(data)
    }

    /// Handles writes to the GIC Distributor and any resulting acknowledgements or IRQ injections.
    ///
    /// The `calling_node` arg is necessary to support callbacks.  The caller may be writing data to
    /// the Distributor that affects other target nodes.
	pub fn handle_write(&mut self, calling_node: NodeIndex, offset: usize, data: VMFaultData) -> Fallible<()> {
        let write_action = self.dist.handle_write(offset, calling_node, data)?;

		match write_action {
			WriteAction::NoAction => {}
			WriteAction::InjectAndAckIRQs((to_inject, to_ack)) => {
				// Handle acks
				if let Some(to_ack) = to_ack {
					for (irq, target_node) in to_ack.iter() {
                        // Update Distributor state
                        self.dist.ack(*irq, *target_node)?;

                        // Handle PPIs and SPIs via callback
                        // SGIs are handled locally in the GIC Distributor.
                        if *irq >= 16 {
                            let qualified_irq;
                            if *irq < 32 {
                                qualified_irq = QualifiedIRQ::QualifiedPPI { node: *target_node, irq: *irq };
                            } else {
                                qualified_irq = QualifiedIRQ::SPI { irq: *irq };
                            }
                            self.callbacks.ack(calling_node, qualified_irq)?;
                        }
					}
				}

				// Handle injections
				if let Some(to_inject) = to_inject {
					for (irq, target_node) in to_inject.iter() {
                        // Inject the interrupt (or push it onto the LR overflow).
                        self.forward_irq(calling_node, *target_node, *irq)?;
					}
				}
			}
			_ => panic!("Unexpected WriteAction")
		}
        Ok(())
    }

    fn forward_irq(&mut self, calling_node: NodeIndex, target_node: NodeIndex, irq: IRQ) -> Fallible<()> {
        let mut index = None;

        // Find the next empty slot in the list register mirror.
        for (i, x) in self.lrs[target_node].mirror.iter().enumerate() {
            if let None = x {
                index = Some(i);
                break;
            }
        }

        // If we found an empty slot, inject the irq and add it to the LR mirror.
        // Otherwise, add it to the LR overflow.
        if let Some(index) = index {
            self.inject_irq(calling_node, target_node, index, irq)?;
        } else if !self.irq_in_lrs_overflow(target_node, irq) {
            self.lrs[target_node].overflow.push_back(irq);
        }

        // TODO: Restore with Event Server.
        // self.pass_wfi();
        Ok(())
    }

    fn inject_irq(&mut self, calling_node: NodeIndex, target_node: NodeIndex, index: usize, irq: IRQ) -> Fallible<()> {
        // Get the priority for the IRQ.
        let priority = usize::try_from(self.dist.get_priority(irq, target_node)?)?;
        let priority = priority >> 3; // The LRs only use the top 5 bits of the 8-bit priority

        // Set the irq pending, check if it should be injected, inject it, then set it active.
        // NOTE: Setting active is an approximation since the seL4 API does not provide insight
        // into when it actually acknowledges an irq, which causes the state transition from
        // pending to active.
        self.dist.set_pending(irq, target_node)?;
        if self.dist.should_inject(irq, target_node) {
            self.dist.set_active(irq, target_node)?;
            self.lrs[target_node].mirror[index] = Some(irq);
            self.callbacks.vcpu_inject_irq(calling_node, target_node, index, irq, priority)?;
            self.callbacks.event(calling_node, target_node)?;
        }

        Ok(())
    }

    // Checks if an irq is in the list register overflow
    // NOTE: We don't bother to perform similar checks for the list register mirror because we risk
    // losing a race, where a seemingly duplicate interrupt arrives, but the thread has actually
    // ended the first interrupt, but we haven't trapped and handled VGICMaintenance fault yet.  In
    // that situation, we would fall out of sync with the actual list register
    fn irq_in_lrs_overflow(&self, node: NodeIndex, irq: IRQ) -> bool {
        for x in self.lrs[node].overflow.iter() {
            if x == &irq {
                return true;
            }
        }

        return false
    }
}
