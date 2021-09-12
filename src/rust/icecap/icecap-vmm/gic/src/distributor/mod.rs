#![allow(dead_code)]
#![allow(unused_variables)]
#![allow(unreachable_patterns)]

use alloc::vec::Vec; // GOAL: Only used during initial distributor allocation.
use core::fmt;
use core::convert::TryFrom;
use core::sync::atomic::Ordering;

use biterate::biterate;

use icecap_sel4::fault::*;
use icecap_sel4::prelude::*; // TODO: Remove.  Just for debug.

use crate::error::*;

mod registers;
mod register;

use registers::{
    GICDistRegWord, GICDistRegByte,
};

use register::{
    Register32,
};

pub const GIC_DIST_SIZE: usize = 0x1000;

pub type IRQ = usize;
pub type CPU = usize;

#[derive(Debug)]
pub(crate) enum IRQType {
    Passthru(IRQHandler),
    Virtual,
    Timer,
    SGI,
}

pub enum WriteAction {
    NoAction,
    InjectAndAckIRQs((Option<Vec<(IRQ, CPU)>>, Option<Vec<(IRQ, CPU)>>)),
}

pub enum ReadAction {
    NoAction,
}

/// GIC Distributor Register Map
/// ARM Generic Interrupt Controller (Architecture version 2.0)
/// Architecture Specification (Issue B.b)
/// Chapter 4 Programmers' Model - Table 4.1
#[derive(Debug, Fail)]
pub struct Distributor {
    num_nodes: usize,

    // GICD_CTLR (RW): enables the forwarding of pending interrupts from the
    // Distributor to the CPU interfaces.
    control: Register32,

    // GICD_TYPER (RO): provides information about the configuration of the GIC.
    ic_type: Register32,

    // GICD_IIDR (RO): info about implementer and revision of the distributor.
    dist_ident: Register32,

    // GICD_IGROUPR (RW): registers provide a status bit for each interrupt.
    irq_group0: Vec<Register32>,
    irq_group: Vec<Register32>,

    // GICD_ISENABLERn (RW): provide a Set-enable bit for each interrupt.
    // GICD_ICENABLERn (RW): provide a Clear-enable bit for each interrupt.
    // NOTE: These registers are associated with the same state. Reads are
    // identical and writing 1 sets or clears the associated register bit.
    enable0: Vec<Register32>,
    enable: Vec<Register32>,

    // GICD_ISPENDRn (RW): provide a Set-pending bit for each interrupt.
    // GICD_ICPENDRn (RW): provide a Clear-pending bit for each interrupt.
    // NOTE: These registers are associated with the same state. Reads are
    // identical and writing 1 sets or clears the associated register bit.
    pending0: Vec<Register32>,
    pending: Vec<Register32>,

    // GICD_ISACTIVERn (RW): provide a Set-active bit for each interrupt.
    // GICD_ICACTIVERn (RW): provide a Clear-active bit for each interrupt.
    // NOTE: These registers are associated with the same state. Reads are
    // identical and writing 1 sets or clears the associated register bit.
    active0: Vec<Register32>,
    active: Vec<Register32>,

    // GICD_IPRIORITYRn (RW): provide an 8-bit priority field for each interrupt.
    priority0: Vec<Vec<Register32>>,
    priority: Vec<Register32>,

    // GICD_ITARGETSRn (RW): provide an 8-bit CPU targets field for each interrupt.
    // NOTE: Registers 0 to 7 are RO.
    targets0: Vec<Vec<Register32>>,
    targets: Vec<Register32>,

    // GICD_ICFGRn (RW): provide a 2-bit Int_config field for each interrupt.
    // NOTE: Register 0 is RO.
    config0: Register32,
    config1: Vec<Register32>,
    config: Vec<Register32>,

    // GICD_NSACRn (RW): enable Secure software to permit Non-secure software on a
    // particular processor to create and manage Group 0 interrupts.
    // NOTE: Not currently implemented.

    // GICD_SGIR (RW): Controls the generation of SGIs.
    // No actual state here.  Writing to this register injects an SGI and
    // affects the pending and active state.

    // GICD_CPENDSGIRn (RW): provide a clear-pending bit for each supported SGI
    // and source processor combination.
    // GICD_SPENDSGIRn (RW): provide a set-pending bit for each supported SGI
    // and source processor combination.
    // NOTE: These registers are associated with the same state. Reads are
    // identical and writing 1 sets or clears the associated register bit.
    // NOTE: This is the view from the *target* processor.
    sgi_pending: Vec<Vec<Register32>>,

    // Identification registers (RO).
    periph_id: Vec<Register32>,
    component_id: Vec<Register32>,
}

impl fmt::Display for Distributor {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "Trivial implementation of Display for Distributor")
    }
}

impl Distributor {

    pub fn new(num_nodes: usize) -> Self {
        let mut gic_dist = Self {
            num_nodes,

            control: Register32::new(0),
            ic_type: Register32::new(0),
            dist_ident: Register32::new(0),

            // irq_group0 is one banked register per node.
            irq_group0: (0..num_nodes).map(|_| Register32::new(0)).collect(),
            irq_group: (0..31).map(|_| Register32::new(0)).collect(),

            // enable0  is one banked register per node.
            enable0: (0..num_nodes).map(|_| Register32::new(0)).collect(),
            enable: (0..31).map(|_| Register32::new(0)).collect(),

            // pending0  is one banked register per node.
            pending0: (0..num_nodes).map(|_| Register32::new(0)).collect(),
            pending: (0..31).map(|_| Register32::new(0)).collect(),

            // active0  is one banked register per node.
            active0: (0..num_nodes).map(|_| Register32::new(0)).collect(),
            active: (0..31).map(|_| Register32::new(0)).collect(),

            // priority0 is 8 banked registers for each node
            priority0: (0..num_nodes)
                .map(|_| (0..8).map(|_| Register32::new(0)).collect())
                .collect(),
            priority: (0..247).map(|_| Register32::new(0)).collect(),

            // targets0 is 8 banked registers for each node
            targets0: (0..num_nodes)
                .map(|_| (0..8).map(|_| Register32::new(0)).collect())
                .collect(),
            targets: (0..247).map(|_| Register32::new(0)).collect(),

            // config0 is RO.
            // config1 is one banked register per node.
            config0: Register32::new(0),
            config1: (0..num_nodes).map(|_| Register32::new(0)).collect(),
            config: (0..62).map(|_| Register32::new(0)).collect(),

            // sgi_pending is 4 banked registers for each node
            sgi_pending: (0..num_nodes)
                .map(|_| (0..4).map(|_| Register32::new(0)).collect())
                .collect(),

            periph_id: (0..12).map(|_| Register32::new(0)).collect(),
            component_id: (0..4).map(|_| Register32::new(0)).collect(),
        };

        gic_dist.reset();
        gic_dist
    }

    // Sweep specified IRQs for all nodes and identify irq/node pairs that should be either injected or
    // acknowledged.  This is used, for example, after writes to the Distributor enabling IRQs,
    // setting IRQs to pending, or changing IRQ targets.
    fn sweep_irqs_to_inject(&self, base_irq: IRQ, num_irqs: usize) -> Vec<(IRQ, CPU)> {
        let mut to_inject: Vec<(IRQ, CPU)> = Vec::new();

        for irq in base_irq..(base_irq + num_irqs) {
            for node_index in 0..self.num_nodes {
                if self.should_inject(irq, node_index) {
                    to_inject.push((irq, node_index));
                    // For SPIs, only push for the first identified target.
                    if irq >= 32 {
                        break;
                    }
                }
            }
        }

        to_inject
    }

    // Sweep specified IRQs for all nodes and identify irq/node pairs that should be acknowledged.
    // This is used, for example, after writes to the Distributor enabling specified IRQs.
    //
    // This is necessary to put IRQs in a known state.  After enabling an IRQ (or the whole GIC),
    // unless we are going to inject the IRQ, we want to make sure the IRQ is not tracked as
    // pending, otherwise, the next time the IRQ fires, we will ignore it.  Therefore, during this
    // sweep we will find any IRQ that should not be injected but IS enabled and pass it back to
    // the GIC to be handled by callbacks.
    fn sweep_irqs_to_ack(&self, base_irq: IRQ, num_irqs: usize) -> Vec<(IRQ, CPU)> {
        let mut to_ack: Vec<(IRQ, CPU)> = Vec::new();

        for irq in base_irq..(base_irq + num_irqs) {
            for node_index in 0..self.num_nodes {
                if !self.should_inject(irq, node_index) && self.is_enabled(irq, node_index) {
                    to_ack.push((irq, node_index));

                    // For SPIs, only push for the first identified target.
                    if irq >= 32 {
                        break;
                    }
                }
            }
        }

        to_ack
    }

    pub fn handle_write(&mut self, offset: usize, node_index: usize, val: VMFaultData) -> Result<WriteAction, IRQError> {
        match val {
            VMFaultData::Word(val) => {
                let reg = GICDistRegWord::from_offset(offset);
                // debug_println!("gic write {:?}: {}", reg, val);
                match reg {
                    GICDistRegWord::GICD_CTLR => {
                        // Set or clear the control register.
                        // If the state has changed, inform the vmm.
                        if val == 1 {
                            let prev = self.control.fetch_or(val, Ordering::SeqCst);
                            if prev == 0 {

                                // Identify newly enabled IRQs and either inject or acknowledge them.
                                let base_irq = 0;
                                let num_irqs = 1020;
                                let to_inject = self.sweep_irqs_to_inject(base_irq, num_irqs);
                                let to_ack = self.sweep_irqs_to_ack(base_irq, num_irqs);

                                if to_inject.len() == 0 && to_ack.len() == 0 {
                                    return Ok(WriteAction::NoAction);
                                } else {
                                    return Ok(WriteAction::InjectAndAckIRQs((Some(to_inject), Some(to_ack))));
                                }
                            }
                        } else if val == 0 {
                            let prev = self.control.fetch_and(val, Ordering::SeqCst);
                            if prev == 1 {
                                return Ok(WriteAction::NoAction);
                            }
                        } else {
                            // Invalid encoding.
                            return Err( IRQError{ irq_error_type:
                                IRQErrorType::InvalidRegisterWrite, });
                        }

                        // If the state hasn't changed, take no action.
                        return Ok(WriteAction::NoAction);
                    }
                    GICDistRegWord::GICD_IIDR |
                        GICDistRegWord::GICD_TYPER => {
                            // These are read-only.
                            return Err( IRQError{ irq_error_type:
                                IRQErrorType::InvalidRegisterWrite, });
                    }
                    GICDistRegWord::GICD_IGROUPRn(reg_num) => {
                        // Set group registers.
                        // - NOTE: Register 0 is banked for each CPU.
                        let group_reg;
                        if reg_num == 0 {
                            group_reg = &mut self.irq_group0[node_index];
                        } else {
                            group_reg = &mut self.irq_group[reg_num - 1];
                        }
                        group_reg.store(val, Ordering::SeqCst);

                        return Ok(WriteAction::NoAction);
                    }
                    GICDistRegWord::GICD_ISENABLERn(reg_num) => {
                        // Set enable registers.
                        // - Writing 1 to an IRQ bit enables the IRQ.
                        // - Writing 0 to an IRQ bit has no effect.
                        // - NOTE: Register 0 is banked for each CPU.
                        if val == 0 {
                            return Ok(WriteAction::NoAction);
                        }

                        let enable_reg;
                        if reg_num == 0 {
                            enable_reg = &mut self.enable0[node_index];
                        } else {
                            enable_reg = &mut self.enable[reg_num - 1];
                        }
                        let prev = enable_reg.fetch_or(val, Ordering::SeqCst);

                        // Identify newly enabled IRQs and either inject or acknowledge them.
                        let num_irqs = 32;
                        let base_irq = (reg_num * num_irqs) as IRQ;
                        let to_inject = self.sweep_irqs_to_inject(base_irq, num_irqs);
                        let to_ack = self.sweep_irqs_to_ack(base_irq, num_irqs);

                        if to_inject.len() == 0 && to_ack.len() == 0 {
                            return Ok(WriteAction::NoAction);
                        } else {
                            return Ok(WriteAction::InjectAndAckIRQs((Some(to_inject), Some(to_ack))));
                        }
                    }
                    GICDistRegWord::GICD_ICENABLERn(reg_num) => {
                        // Clear enable registers.
                        // - Writing 1 to an IRQ bit disables the IRQ.
                        // - Writing 0 to an IRQ bit has no effect.
                        // - NOTE: Register 0 is banked for each CPU.
                        if val == 0 {
                            return Ok(WriteAction::NoAction);
                        }

                        let enable_reg;
                        if reg_num == 0 {
                            enable_reg = &mut self.enable0[node_index];
                        } else {
                            enable_reg = &mut self.enable[reg_num];
                        }
                        enable_reg.fetch_and(!val, Ordering::SeqCst);

                        return Ok(WriteAction::NoAction);
                    }
                    GICDistRegWord::GICD_ISPENDRn(reg_num) => {
                        // Set pending registers.
                        // - Writing 1 to an IRQ bit sets the IRQ pending.
                        // - Writing 0 to an IRQ bit has no effect.
                        // - This is used to preserve and restore GIC state, but
                        //   changing a pending register bit does result in an
                        //   interrupt being injected.
                        // - NOTE: Register 0 is banked for each CPU.
                        if val == 0 {
                            return Ok(WriteAction::NoAction);
                        }

                        let pending_reg;
                        if reg_num == 0 {
                            // IRQs 0->15 are SGIs and are RO.
                            // Writes are ignored.
                            if val & 0xFFFF != 0 {
                                return Ok(WriteAction::NoAction);
                            }
                            pending_reg = &mut self.pending0[node_index];
                        } else {
                            pending_reg = &mut self.pending[reg_num - 1];
                        }
                        let prev = pending_reg.fetch_or(val, Ordering::SeqCst);

                        // Identify newly pending IRQs and inject them.
                        // NOTE: We do not need to acknowledge any IRQs here because none of these
                        // will be newly enabled.
                        let num_irqs = 32;
                        let base_irq = (reg_num * num_irqs) as IRQ;
                        let to_inject = self.sweep_irqs_to_inject(base_irq, num_irqs);

                        if to_inject.len() == 0 {
                            return Ok(WriteAction::NoAction);
                        } else {
                            return Ok(WriteAction::InjectAndAckIRQs((Some(to_inject), None)));
                        }
                    }
                    GICDistRegWord::GICD_ICPENDRn(reg_num) => {
                        // Clear pending registers.
                        // - Writing 1 to an IRQ bit clears the pending state.
                        // - Writing 0 to an IRQ bit has no effect.
                        // - This is used to preserve and restore GIC state, so
                        //   changing a pending register bit doesn't have an
                        //   immediate effect.
                        // - NOTE: Register 0 is banked for each CPU.
                        if val == 0 {
                            return Ok(WriteAction::NoAction);
                        }

                        let pending_reg;
                        if reg_num == 0 {
                            // IRQs 0->15 are SGIs and are RO.
                            if val & 0xFFFF != 0 {
                                return Err( IRQError{ irq_error_type:
                                    IRQErrorType::InvalidRegisterWrite, });
                            }
                            pending_reg = &mut self.pending0[node_index];
                        } else {
                            pending_reg  = &mut self.pending[reg_num - 1];
                        }
                        pending_reg.fetch_and(!val, Ordering::SeqCst);

                        return Ok(WriteAction::NoAction);
                    }
                    GICDistRegWord::GICD_ISACTIVERn(reg_num) => {
                        // Set active registers.
                        // - Writing 1 to an IRQ bit sets the IRQ active.
                        // - Writing 0 to an IRQ bit has no effect.
                        // - This is used to preserve and restore GIC state, so
                        //   changing an active register bit doesn't have an
                        //   immediate effect.
                        // - NOTE: Register 0 is banked for each CPU.
                        if val == 0 {
                            return Ok(WriteAction::NoAction);
                        }

                        let active_reg;
                        if reg_num == 0 {
                            active_reg = &mut self.active0[node_index];
                        } else {
                            active_reg = &mut self.active[reg_num - 1];
                        }
                        active_reg.fetch_or(val, Ordering::SeqCst);

                        return Ok(WriteAction::NoAction);
                    }
                    GICDistRegWord::GICD_ICACTIVERn(reg_num) => {
                        // Clear active registers.
                        // - Writing 1 to an IRQ bit clears the active state.
                        // - Writing 0 to an IRQ bit has no effect.
                        // - This is used to preserve and restore GIC state; but
                        //   changing an active register bit doesn't have an
                        //   immediate effect.
                        // - NOTE: Register 0 is banked for each CPU.
                        if val == 0 {
                            return Ok(WriteAction::NoAction);
                        }

                        let active_reg;
                        if reg_num == 0 {
                            active_reg = &mut self.active0[node_index];
                        } else {
                            active_reg  = &mut self.active[reg_num - 1];
                        }
                        active_reg.fetch_and(!val, Ordering::SeqCst);

                        return Ok(WriteAction::NoAction);
                    }
                    GICDistRegWord::GICD_IPRIORITYRn(reg_num) => {
                        // Set priority registers.
                        // - Each IRQ has an 8 bit priority field.
                        // - This logic block writes an entire word, including
                        //   priority fields for four IRQs.
                        // - NOTE: Registers 0 to 7 banked for each CPU.
                        let priority_reg;
                        if reg_num < 8 {
                            priority_reg = &mut self.priority0[node_index][reg_num];
                        } else {
                            priority_reg = &mut self.priority[reg_num - 8];
                        }
                        priority_reg.store(val, Ordering::SeqCst);

                        return Ok(WriteAction::NoAction);
                    }
                    GICDistRegWord::GICD_ITARGETSRn(reg_num) => {
                        // Set target registers.
                        // - Each IRQ has an 8 bit target field.
                        // - This logic block writes an entire word, including
                        //   target fields for four IRQs.
                        // - For pending interrupts:
                        //   - Adding a CPU as a target sets pending for the CPU.
                        //   - Removing a CPU as a target clears pending for the CPU.
                        // - NOTE: Registers 0 to 7 banked for each CPU and are RO.
                        let targets_reg;
                        if reg_num < 8 {
                            // These are read-only.
                            return Err( IRQError{ irq_error_type:
                                IRQErrorType::InvalidRegisterWrite, });
                        } else {
                            targets_reg = &mut self.targets[reg_num - 8];
                        }
                        let prev = targets_reg.swap(val, Ordering::SeqCst);

                        let new_cpus = val & !prev;
                        if new_cpus == 0 {
                            return Ok(WriteAction::NoAction);
                        }

                        // Identify newly targeted IRQs and inject or ack them.
                        let num_irqs = 4;
                        let base_irq = (reg_num * num_irqs) as IRQ;
                        let to_inject = self.sweep_irqs_to_inject(base_irq, num_irqs);
                        let to_ack = self.sweep_irqs_to_ack(base_irq, num_irqs);

                        if to_inject.len() == 0 && to_ack.len() == 0 {
                            return Ok(WriteAction::NoAction);
                        } else {
                            return Ok(WriteAction::InjectAndAckIRQs((Some(to_inject), Some(to_ack))));
                        }
                    }
                    GICDistRegWord::GICD_ICFGRn(reg_num) => {
                        // Set trigger configuration registers.
                        // - Each IRQ has a 2 bit field identifying if the IRQ is
                        //   level or edge triggered.
                        // - This logic block writes an entire word, including
                        //   config fields for eight IRQs.
                        // - An IRQ must be disabled to change its config, or
                        //   the GIC behaviour is UNPREDICTABLE.
                        // - NOTE: SGI configuration fields (config0) are RO.
                        // - NOTE: PPI configuration fields (config1) are banked.

                        let config_reg;
                        if reg_num == 0 {
                            // SGI IRQ #s are 0-15 and fill the 0th register.
                            // As these are RO, writing has no effect.
                            return Ok(WriteAction::NoAction);
                        } else if reg_num == 1 {
                            config_reg = &mut self.config1[node_index];
                        } else {
                            config_reg = &mut self.config[reg_num - 2];
                        }
                        config_reg.store(val, Ordering::SeqCst);
                        return Ok(WriteAction::NoAction);
                    }
                    GICDistRegWord::GICD_NSACRn(reg_num) => {
                        // Set non-secure access control registers.
                        // - Not implemented.  The VM is not in Secure mode.
                        return Err( IRQError{ irq_error_type: IRQErrorType::InvalidRegisterWrite, });
                    }
                    GICDistRegWord::GICD_SGIR => {
                        // Inject SGIs into one or more CPU interfaces.
                        // - GICD_SGIR is WO, and writing to it injects SGIs
                        //   into one or more target CPUs from the source CPU.

                        // Decode the register write.
                        let sgi_int_id = (val & 0xFF) as IRQ;
                        let cpu_target_list = (val >> 16) & 0xFF;
                        let target_list_filter = (val >> 24) & 0x3;

                        let mut to_inject: Vec<(IRQ, CPU)> = Vec::new();
                        let irq = sgi_int_id as IRQ;

                        // Use target_list_filter to interpret where to inject
                        // the specified sgi_int_id.
                        if target_list_filter == 0b00 {
                            // Forward IRQ to CPU interfaces in cpu_target_list
                            for i in biterate(cpu_target_list) {
                                let cpu = i as CPU;
                                self.set_pending(irq, cpu).unwrap();
                                if self.should_inject(irq, cpu) {
                                    to_inject.push((irq, cpu));
                                }
                            }
                        } else if target_list_filter == 0b01 {
                            // Forward IRQ to all CPU interfaces except source CPU
                            assert!(node_index < 8);
                            let cpu_target_list = 0b11111111 ^ (1 << node_index);
                            for i in biterate(cpu_target_list) {
                                let cpu = i as CPU;
                                self.set_pending(irq, cpu).unwrap();
                                if self.should_inject(irq, cpu) {
                                    to_inject.push((irq, cpu));
                                }
                            }
                        } else if target_list_filter == 0b10 {
                            // Forward IRQ to only to the source CPU
                            let cpu = node_index as CPU;
                            self.set_pending(irq, cpu).unwrap();
                            if self.should_inject(irq, cpu) {
                                to_inject.push((irq, cpu));
                            }
                        } else {
                            // 0b11 is Reserved.  Take no action.
                            return Ok(WriteAction::NoAction);
                        }

                        if to_inject.len() == 0 {
                            return Ok(WriteAction::NoAction);
                        } else {
                            return Ok(WriteAction::InjectAndAckIRQs((Some(to_inject), None)));
                        }
                    }
                    GICDistRegWord::GICD_CPENDSGIRn(reg_num) => {
                        // Clear SGI pending registers.
                        // - Writing 1 to an IRQ bit clears the pending state.
                        // - Writing 0 to an IRQ bit has no effect.
                        // - NOTE: Registers are banked for each CPU.
                        if val == 0 {
                            return Ok(WriteAction::NoAction);
                        }

                        let sgi_pending_reg;
                        sgi_pending_reg  = &mut self.sgi_pending[node_index][reg_num];
                        let prev = sgi_pending_reg.fetch_and(!val, Ordering::SeqCst);

                        // Identify any IRQs for this node that are no longer
                        // pending and clear that IRQ in the pending register
                        // to support reads of GICD_ISPENDRn or GICD_ICPENDRn.
                        let still_pending = prev & !val;
                        let base_irq = (reg_num * 4) as IRQ;
                        let mut mask: u32 = 0xFF;
                        for irq in base_irq..base_irq + 4 {
                            mask = mask << ((irq - base_irq) * 8);
                            if still_pending & mask == 0 {
                                self.clear_pending(irq, node_index).unwrap();
                            }
                        }

                        return Ok(WriteAction::NoAction);
                    }
                    GICDistRegWord::GICD_SPENDSGIRn(reg_num) => {
                        // Set SGI pending registers.
                        // - Writing 1 to an IRQ bit sets the pending state.
                        // - Writing 0 to an IRQ bit has no effect.
                        // - NOTE: All registers are banked for each CPU.
                        if val == 0 {
                            return Ok(WriteAction::NoAction);
                        }

                        let sgi_pending_reg;
                        sgi_pending_reg  = &mut self.sgi_pending[node_index][reg_num];
                        let prev = sgi_pending_reg.fetch_or(val, Ordering::SeqCst);

                        let num_irqs = 4;
                        let base_irq = (reg_num * num_irqs) as IRQ;

                        // Identify any newly pending IRQs for this node
                        // and set the pending register to support
                        // reads of GICD_ISPENDRn or GICD_ICPENDRn.
                        let newly_pending = val & !prev;
                        let mut mask: u32 = 0xFF;
                        for irq in base_irq..base_irq + 4 {
                            mask = mask << ((irq - base_irq) * 8);
                            if newly_pending & mask != 0 {
                                self.set_pending(irq, node_index).unwrap();
                            }
                        }

                        // Identify newly pending IRQs and inject them.
                        let to_inject = self.sweep_irqs_to_inject(base_irq, num_irqs);

                        if to_inject.len() == 0 {
                            return Ok(WriteAction::NoAction);
                        } else {
                            return Ok(WriteAction::InjectAndAckIRQs((Some(to_inject), None)));
                        }
                    }
                    GICDistRegWord::ICPIDRn(reg_num) |
                        GICDistRegWord::ICCIDRn(reg_num) => {
                            // These are read-only.
                            return Err( IRQError{ irq_error_type:
                                IRQErrorType::InvalidRegisterWrite, });
                        }
                    _ => {
                        // Invalid register.
                        return Err( IRQError{ irq_error_type: IRQErrorType::InvalidRegisterWrite, });
                    }
                }
            }
            VMFaultData::Byte(val) => {
                let reg = GICDistRegByte::from_offset(offset);
                panic!("Byte-accessible writes to GIC not yet implemented.");
            }
            _ => panic!("Writes to GIC distributor registers must by byte- or word-aligned.")
        }
    }

    pub fn handle_read(&self, offset: usize, node_index: usize, width: VMFaultWidth) -> Result<(VMFaultData, ReadAction), IRQError> {
        match width {
            VMFaultWidth::Word => {
                let reg = GICDistRegWord::from_offset(offset);
                match reg {
                    GICDistRegWord::GICD_CTLR => {
                        // Read the control register.
                        let val = self.control.load(Ordering::SeqCst);
                        return Ok((VMFaultData::Word(val), ReadAction::NoAction));
                    }
                    GICDistRegWord::GICD_TYPER => {
                        // Read the interrupt controller type register.
                        let val = self.ic_type.load(Ordering::SeqCst);
                        return Ok((VMFaultData::Word(val), ReadAction::NoAction));
                    }
                    GICDistRegWord::GICD_IIDR => {
                        // Read the implementer identification register.
                        let val = self.dist_ident.load(Ordering::SeqCst);
                        return Ok((VMFaultData::Word(val), ReadAction::NoAction));
                    }
                    GICDistRegWord::GICD_IGROUPRn(reg_num) => {
                        // Read group registers.
                        // NOTE: Register 0 is banked for each CPU.
                        let group_reg;
                        if reg_num == 0 {
                            group_reg = &self.irq_group0[node_index];
                        } else {
                            group_reg = &self.irq_group[reg_num - 1];
                        }
                        let val = group_reg.load(Ordering::SeqCst);
                        return Ok((VMFaultData::Word(val), ReadAction::NoAction));
                    }
                    GICDistRegWord::GICD_ISENABLERn(reg_num) |
                        GICDistRegWord::GICD_ICENABLERn(reg_num) => {
                        // Read enable registers.
                        // NOTE: Register 0 is banked for each CPU.
                        let enable_reg;
                        if reg_num == 0 {
                            enable_reg = &self.enable0[node_index];
                        } else {
                            enable_reg = &self.enable[reg_num];
                        }
                        let val = enable_reg.load(Ordering::SeqCst);
                        return Ok((VMFaultData::Word(val), ReadAction::NoAction));
                    }
                    GICDistRegWord::GICD_ISPENDRn(reg_num) |
                        GICDistRegWord::GICD_ICPENDRn(reg_num) => {
                        // Read pending registers.
                        // NOTE: Register 0 is banked for each CPU.
                        let pending_reg;
                        if reg_num == 0 {
                            pending_reg = &self.pending0[node_index];
                        } else {
                            pending_reg = &self.pending[reg_num - 1];
                        }
                        let val = pending_reg.load(Ordering::SeqCst);
                        return Ok((VMFaultData::Word(val), ReadAction::NoAction));
                    }
                    GICDistRegWord::GICD_ISACTIVERn(reg_num) |
                        GICDistRegWord::GICD_ICACTIVERn(reg_num) => {
                        // Read active registers.
                        // NOTE: Register 0 is banked for each CPU.
                        let active_reg;
                        if reg_num == 0 {
                            active_reg = &self.active0[node_index];
                        } else {
                            active_reg = &self.active[reg_num - 1];
                        }
                        let val = active_reg.load(Ordering::SeqCst);
                        return Ok((VMFaultData::Word(val), ReadAction::NoAction));
                    }
                    GICDistRegWord::GICD_IPRIORITYRn(reg_num) => {
                        // Read register priorities.
                        // This logic block reads an entire word, including
                        // priority fields for four IRQs.
                        // NOTE: Registers 0 to 7 banked for each CPU.
                        let priority_reg;
                        if reg_num < 8 {
                            priority_reg = &self.priority0[node_index][reg_num];
                        } else {
                            priority_reg = &self.priority[reg_num - 8];
                        }
                        let val = priority_reg.load(Ordering::SeqCst);
                        return Ok((VMFaultData::Word(val), ReadAction::NoAction));
                    }
                    GICDistRegWord::GICD_ITARGETSRn(reg_num) => {
                        // Read target registers.
                        // This logic block reads an entire word, including
                        // target fields for four IRQs.
                        // NOTE: Registers 0 to 7 banked for each CPU.
                        let targets_reg;
                        if reg_num < 8 {
                            targets_reg = &self.targets0[node_index][reg_num];
                        } else {
                            targets_reg = &self.targets[reg_num - 8];
                        }
                        let val = targets_reg.load(Ordering::SeqCst);
                        return Ok((VMFaultData::Word(val), ReadAction::NoAction));
                    }
                    GICDistRegWord::GICD_ICFGRn(reg_num) => {
                        // Read trigger configuration registers.
                        // NOTE: Register 1 is banked for each CPU.
                        let config;
                        if reg_num == 0 {
                            config = &self.config0;
                        } else if reg_num == 1 {
                            config = &self.config1[node_index];
                        } else {
                            config = &self.config[reg_num - 2];
                        }
                        let val = config.load(Ordering::SeqCst);
                        return Ok((VMFaultData::Word(val), ReadAction::NoAction));
                    }
                    GICDistRegWord::GICD_NSACRn(reg_num) => {
                        // Read non-secure access control registers.
                        // - Not implemented.  The VM is not in Secure mode.
                        return Err( IRQError{ irq_error_type: IRQErrorType::InvalidRegisterRead, });
                    }
                    GICDistRegWord::GICD_SGIR => {
                        // This is write-only.
                        return Err( IRQError{ irq_error_type: IRQErrorType::InvalidRegisterRead, });
                    }
                    GICDistRegWord::GICD_CPENDSGIRn(reg_num) |
                        GICDistRegWord::GICD_SPENDSGIRn(reg_num) => {
                        // Read sgi pending registers.
                        // NOTE: Registers are banked for each CPU.
                        let sgi_pending_reg;
                        sgi_pending_reg = &self.sgi_pending[node_index][reg_num];
                        let val = sgi_pending_reg.load(Ordering::SeqCst);
                        return Ok((VMFaultData::Word(val), ReadAction::NoAction));
                    }
                    GICDistRegWord::ICPIDRn(reg_num) => {
                        // Read peripheral ID registers.
                        let periph_id_reg;
                        periph_id_reg = &self.periph_id[reg_num];
                        let val = periph_id_reg.load(Ordering::SeqCst);
                        return Ok((VMFaultData::Word(val), ReadAction::NoAction));
                    }
                    GICDistRegWord::ICCIDRn(reg_num) => {
                        // Read component ID registers.
                        let component_id_reg;
                        component_id_reg = &self.component_id[reg_num];
                        let val = component_id_reg.load(Ordering::SeqCst);
                        return Ok((VMFaultData::Word(val), ReadAction::NoAction));
                    }
                    _ => {
                        // Invalid register.
                        return Err( IRQError{ irq_error_type: IRQErrorType::InvalidRegisterRead, });
                    }
                }
            }
            VMFaultWidth::Byte => {
                let reg = GICDistRegByte::from_offset(offset);
                panic!("Byte-accessible reads from GIC not yet implemented.");
            }
            _ => panic!("Reads from GIC distributor registers must by byte- or word-aligned.")
        }
    }

    pub(crate) fn should_inject(&self, irq: IRQ, cpu: CPU) -> bool {
        self.is_gic_enabled() && self.is_enabled(irq, cpu) &&
            self.is_target(irq, cpu) && self.is_pending(irq, cpu) &&
            !self.is_active(irq, cpu)
    }

    fn is_gic_enabled(&self) -> bool {
        if self.control.load(Ordering::SeqCst) == 1 {
            return true;
        } else {
            return false;
        }
    }

    /// Get the priority of the given irq for the given cpu.
    pub(crate) fn get_priority(&self, irq: IRQ, cpu: CPU) -> Result<u32, IRQError> {
        if usize::try_from(cpu).unwrap() >= self.num_nodes {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidCPU(cpu) });
        }

        let priority_reg;
        let reg_num = irq / 4;
        if reg_num < 8 {
            priority_reg = &self.priority0[cpu][reg_num];
        } else {
            priority_reg = &self.priority[reg_num - 8];
        }

        let mask = 0xFF << ((irq % 4) * 8);
        let val = priority_reg.load(Ordering::SeqCst);
        let priority = (val & mask) >> ((irq % 4) * 8);

        Ok(priority)
    }

    fn is_enabled(&self, irq: IRQ, cpu: CPU) -> bool {
        if usize::try_from(cpu).unwrap() >= self.num_nodes {
            return false;
        }

        let reg;
        if irq < 32 {
            reg = &self.enable0[cpu];
        } else {
            reg = &self.enable[irq / 32 - 1];
        }
        let val = reg.load(Ordering::SeqCst);
        let shift = irq % 32;
        if (val >> shift) & 1 == 1 {
            true
        } else {
            false
        }
    }

    // Gets the bit-packed list of target nodes for the given irq.
    //
    // This is only applicable to SPIs, which are shared between nodes.  For SGIs and PPIs, which
    // are node-specific, `is_target()` should be used instead.
    pub(crate) fn get_spi_targets(&self, irq: IRQ) -> u32 {
        assert!(irq >= 32);

        let reg = &self.targets[(irq / 4) - 8];
        let val = reg.load(Ordering::SeqCst);
        let shift = (irq % 4) * 8;
        let cpus = (val >> shift) & 0xFF;

        cpus
    }

    // Identifies if the given cpu is a target of the given irq.
    pub(crate) fn is_target(&self, irq: IRQ, cpu: CPU) -> bool {
        if usize::try_from(cpu).unwrap() >= self.num_nodes {
            return false;
        }

        let reg;
        if irq < 32 {
            reg = &self.targets0[cpu][irq / 4];
        } else {
            reg = &self.targets[(irq / 4) - 8];
        }
        let val = reg.load(Ordering::SeqCst);
        let shift = (irq % 4) * 8;
        let cpus = (val >> shift) & 0xFF;
        if (cpus >> cpu) & 1 == 1 {
            true
        } else {
            false
        }
    }

    fn is_pending(&self, irq: IRQ, cpu: CPU) -> bool {
        if usize::try_from(cpu).unwrap() >= self.num_nodes {
            return false;
        }

        let reg;
        if irq < 32 {
            reg = &self.pending0[cpu];
        } else {
            reg = &self.pending[irq / 32 - 1];
        }
        let val = reg.load(Ordering::SeqCst);
        let shift = irq % 32;
        if (val >> shift) & 1 == 1 {
            true
        } else {
            false
        }
    }

    fn clear_pending(&mut self, irq: IRQ, cpu: CPU) -> Result<(), IRQError> {
        if usize::try_from(cpu).unwrap() >= self.num_nodes {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidCPU(cpu) });
        }

        let reg;
        if irq < 32 {
            reg = &mut self.pending0[cpu];
        } else {
            reg = &mut self.pending[irq / 32 - 1];
        }

        let shift = irq % 32;
        let val: u32 = 1 << shift;
        reg.fetch_and(!val, Ordering::SeqCst);

        Ok(())
    }

    pub(crate) fn set_pending(&mut self, irq: IRQ, cpu: CPU) -> Result<(), IRQError> {
        if usize::try_from(cpu).unwrap() >= self.num_nodes {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidCPU(cpu) });
        }

        let reg;
        if irq < 32 {
            reg = &mut self.pending0[cpu];
        } else {
            reg = &mut self.pending[irq / 32 - 1];
        }

        let shift = irq % 32;
        let val: u32 = 1 << shift;
        reg.fetch_or(val, Ordering::SeqCst);

        Ok(())
    }

    fn set_sgi_pending(&mut self, irq: IRQ, source_cpu: CPU, target_cpu: CPU) -> Result<(), IRQError> {
        if source_cpu >= self.num_nodes {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidCPU(source_cpu) });
        }

        if target_cpu >= self.num_nodes {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidCPU(target_cpu) });
        }

        if irq > 16 {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidIRQ(irq) });
        }

        // Identify the correct SGI register for the target cpu
        let reg_num = irq / 4;
        let reg = &mut self.sgi_pending[target_cpu][reg_num];

        // Calculate the bit for the given IRQ and source register
        let val = 1 << (source_cpu + (irq % 4) * 8);

        // Update the register
        reg.fetch_or(val, Ordering::SeqCst);

        // Identify if this is a newly-pending IRQ for this node
        // and set the pending register to support reads of
        // GICD_ISPENDRn or GICD_ICPENDRn.
        if !self.is_pending(irq, target_cpu) {
            self.set_pending(irq, target_cpu).unwrap();
        }

        Ok(())
    }

    fn clear_sgi_pending(&mut self, irq: IRQ, source_cpu: CPU, target_cpu: CPU) -> Result<(), IRQError> {
        if usize::try_from(source_cpu).unwrap() >= self.num_nodes {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidCPU(source_cpu) });
        }

        if usize::try_from(target_cpu).unwrap() >= self.num_nodes {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidCPU(target_cpu) });
        }

        if irq > 16 {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidIRQ(irq) });
        }

        // Identify the correct SGI register for the target cpu
        let reg_num = irq / 4;
        let reg = &mut self.sgi_pending[target_cpu][reg_num];

        // Calculate the bit for the given IRQ and source register
        let val = 1 << (source_cpu + (irq % 4) * 8);

        // Update the register
        let prev = reg.fetch_and(!val, Ordering::SeqCst);

        // Identify if this IRQ is no longer pending for this node
        // and clear the pending register to support reads of
        // GICD_ISPENDRn or GICD_ICPENDRn.
        let still_pending = prev & !val;
        let mask: u32 = 0xFF << ((irq % 4) * 8);
        if still_pending & mask == 0 {
            self.clear_pending(irq, target_cpu).unwrap();
        }

        Ok(())
    }

    fn is_active(&self, irq: IRQ, cpu: CPU) -> bool {
        if usize::try_from(cpu).unwrap() >= self.num_nodes {
            return false;
        }

        let reg;
        if irq < 32 {
            reg = &self.active0[cpu];
        } else {
            reg = &self.active[irq / 32 - 1];
        }
        let val = reg.load(Ordering::SeqCst);
        let shift = irq % 32;
        if (val >> shift) & 1 == 1 {
            true
        } else {
            false
        }
    }

    fn clear_active(&mut self, irq: IRQ, cpu: CPU) -> Result<(), IRQError> {
        if usize::try_from(cpu).unwrap() >= self.num_nodes {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidCPU(cpu) });
        }

        let reg;
        if irq < 32 {
            reg = &mut self.active0[cpu];
        } else {
            reg = &mut self.active[irq / 32 - 1];
        }

        let shift = irq % 32;
        let val: u32 = 1 << shift;
        reg.fetch_and(!val, Ordering::SeqCst);

        Ok(())
    }

    // The seL4 API does not tell userland when an interrupt is acknowledged (i.e., transitioned
    // from pending to active).  Therefore, the GIC must infer the state transition and should do
    // so as soon as the seL4 API call to inject an IRQ is invoked.
    pub(crate) fn set_active(&mut self, irq: IRQ, cpu: CPU) -> Result<(), IRQError> {
        if usize::try_from(cpu).unwrap() >= self.num_nodes {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidCPU(cpu) });
        }

        let reg;
        if irq < 32 {
            reg = &mut self.active0[cpu];
        } else {
            reg = &mut self.active[irq / 32 - 1];
        }

        let shift = irq % 32;
        let val: u32 = 1 << shift;
        reg.fetch_or(val, Ordering::SeqCst);

        Ok(())
    }

    // The seL4 API does not tell userland when an interrupt is acknowledged (i.e., transitioned
    // from pending to active).  In seL4 API terms, an ack is equivalent to an end-of-interrupt
    // (EOI), which should clear the pending state rather than setting the active state.
    pub fn ack(&mut self, irq: IRQ, node_index: usize) -> Result<(), IRQError> {
        let cpu = node_index as CPU;

        if usize::try_from(cpu).unwrap() >= self.num_nodes {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidCPU(cpu) });
        }

        if irq < 16 {
            self.clear_sgi_pending(irq, 0, cpu)?;
        } else {
            self.clear_pending(irq, cpu)?;
        }

        self.clear_active(irq, cpu)?;

        Ok(())
    }

    // Returns a list of vCPU targets for a given IRQ.
    pub fn get_vcpu_targets(&self, irq: IRQ) -> Vec<usize> {
        let mut vcpu_targets = Vec::new();

        for cpu in 0..8 {
            if self.is_target(irq, cpu as CPU) {
                vcpu_targets.push(cpu);
            }
        }

        vcpu_targets
    }

    // Establishes the reset values from the Arm GICv2 architecture spec.
    pub fn reset(&mut self) {
        self.ic_type.store(0x0000fce7, Ordering::SeqCst); // RO
        self.dist_ident.store(0x0200043b, Ordering::SeqCst); // RO

        // Reset per-CPU enable and _clr registers
        for i in 0..self.num_nodes {
            self.enable0[i].store(0x0000ffff, Ordering::SeqCst); // 16-bit RO
        }

        // Reset values for interrupt configuration registers.
        // PPIs in config1 are banked per-CPU.
        self.config0.store(0xaaaaaaaa, Ordering::SeqCst); // RO
        for i in 0..self.num_nodes {
            self.config1[i].store(0x55540000, Ordering::SeqCst);
        }
        self.config[0].store(0x55555555, Ordering::SeqCst);
        self.config[1].store(0x55555555, Ordering::SeqCst);
        self.config[2].store(0x55555555, Ordering::SeqCst);
        self.config[3].store(0x55555555, Ordering::SeqCst);
        self.config[4].store(0x55555555, Ordering::SeqCst);
        self.config[5].store(0x55555555, Ordering::SeqCst);
        self.config[6].store(0x55555555, Ordering::SeqCst);
        self.config[7].store(0x55555555, Ordering::SeqCst);
        self.config[8].store(0x55555555, Ordering::SeqCst);
        self.config[9].store(0x55555555, Ordering::SeqCst);
        self.config[10].store(0x55555555, Ordering::SeqCst);
        self.config[11].store(0x55555555, Ordering::SeqCst);
        self.config[12].store(0x55555555, Ordering::SeqCst);
        self.config[13].store(0x55555555, Ordering::SeqCst);

        // Configure per-CPU SGI/PPI target registers
        // 1. Reset each register to 0x0.
        // 2. Iterate through each CPU and its 8 banked registers.
        // 3. Bitwise-or a 1 in the CPU target field for each interrupt.
        // e.g., for CPU1, targets0[1][j] = 00000010 00000010 00000010 00000010
        for (idx, bank) in self.targets0.iter_mut().enumerate() {
            for target in bank {
                target.store(0x0, Ordering::SeqCst);
                for irq in 0..4 {
                    target.fetch_or( (1 << idx) << (irq * 8), Ordering::SeqCst);
                }
            }
        }

        // Deliver the SPI interrupts to the first CPU interface
        // These are the remaining 247 target registers that are shared by
        // all CPUs (which, combined with the 8 target0 registers banked on
        // a per-CPU basis, results in 255 target registers per CPU).
        for target in self.targets.iter_mut() {
            target.store(0x01010101, Ordering::SeqCst);
        }

        // Identification
        self.periph_id[4].store(0x04, Ordering::SeqCst); // RO
        self.periph_id[8].store(0x90, Ordering::SeqCst); // RO
        self.periph_id[9].store(0xb4, Ordering::SeqCst); // RO
        self.periph_id[10].store(0x2b, Ordering::SeqCst); // RO
        self.component_id[0].store(0x0d, Ordering::SeqCst); // RO
        self.component_id[1].store(0xf0, Ordering::SeqCst); // RO
        self.component_id[2].store(0x05, Ordering::SeqCst); // RO
        self.component_id[3].store(0xb1, Ordering::SeqCst); // RO
    }
}

//

fn irq_idx(irq: IRQ) -> usize {
    irq / 32
}

fn irq_bit(irq: IRQ) -> u32 {
    1 << (irq % 32)
}
