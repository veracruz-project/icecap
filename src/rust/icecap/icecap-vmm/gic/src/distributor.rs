use alloc::vec::Vec; // GOAL: Only used during initial distributor allocation.
// use core::ops::Deref;
// use core::ptr::write_bytes;
use core::mem;
use core::fmt;
use core::convert::TryFrom;
use core::sync::atomic::{AtomicU32, Ordering};

use biterate::biterate;

// use icecap_failure::{Fallible, Error};

use icecap_sel4::fault::*;
use icecap_sel4::prelude::*; // TODO: Remove.  Just for debug.


pub const GIC_DIST_SIZE: usize = 0x1000;

pub type IRQ = usize;
pub type CPU = usize;

#[derive(Debug)]
pub enum IRQType {
    Passthru(IRQHandler),
    Virtual,
    Timer,
    SGI,
}

// Support errors associated with IRQs.
enum IRQErrorType {
    InvalidCPU(CPU),
    InvalidIRQ(IRQ),
}

struct IRQError {
    irq_error_type: IRQErrorType,
}

impl IRQError {
    fn new(irq_error_type: IRQErrorType) -> IRQError {
        IRQError {
            irq_error_type,
        }
    }
}

impl fmt::Display for IRQError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self.irq_error_type {
            IRQErrorType::InvalidCPU(CPU) => {
                write!(f, "Accessing IRQ state for an invalid CPU: {}", CPU)
            }
            _ => {
                write!(f, "Unknown IRQ error")
            }
        }
    }
}

impl fmt::Debug for IRQError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self.irq_error_type {
            IRQErrorType::InvalidCPU(CPU) => {
                write!(f, "Accessing IRQ state for an invalid CPU: {}", CPU)
            }
            _ => {
                write!(f, "Unknown IRQ error")
            }
        }
    }
}

pub enum WriteAction {
    NoAction,
    InjectAndAckIRQs((Option<Vec<(IRQ, CPU)>>, Option<Vec<(IRQ, CPU)>>)),
}

pub enum ReadAction {
    NoAction,
}

pub enum PPIAction {
    NoAction,
    InjectIRQ,
}

pub enum SGIAction {
    NoAction,
    InjectIRQ,
}

pub enum SPIAction {
    NoAction,
    InjectIRQ,
}

pub enum AckAction {
    NoAction,
}

// GIC Distributor Register Map
// ARM Generic Interrupt Controller (Architecture version 2.0)
// Architecture Specification (Issue B.b)
// Chapter 4 Programmers' Model - Table 4.1
//
// API:
// handle_write()
// handle_read()
// handle_spi()
// handle_ppi()
#[derive(Debug)]
pub struct Distributor {
    num_nodes: usize,

    // GICD_CTLR (RW): enables the forwarding of pending interrupts from the
    // Distributor to the CPU interfaces.
    control: AtomicU32,

    // GICD_TYPER (RO): provides information about the configuration of the GIC.
    ic_type: AtomicU32,

    // GICD_IIDR (RO): info about implementer and revision of the distributor.
    dist_ident: AtomicU32,

    // GICD_IGROUPR (RW): registers provide a status bit for each interrupt.
    irq_group0: Vec<AtomicU32>,
    irq_group: Vec<AtomicU32>,

    // GICD_ISENABLERn (RW): provide a Set-enable bit for each interrupt.
    // GICD_ICENABLERn (RW): provide a Clear-enable bit for each interrupt.
    // NOTE: These registers are associated with the same state. Reads are
    // identical and writing 1 sets or clears the associated register bit.
    enable0: Vec<AtomicU32>,
    enable: Vec<AtomicU32>,

    // GICD_ISPENDRn (RW): provide a Set-pending bit for each interrupt.
    // GICD_ICPENDRn (RW): provide a Clear-pending bit for each interrupt.
    // NOTE: These registers are associated with the same state. Reads are
    // identical and writing 1 sets or clears the associated register bit.
    pending0: Vec<AtomicU32>,
    pending: Vec<AtomicU32>,

    // GICD_ISACTIVERn (RW): provide a Set-active bit for each interrupt.
    // GICD_ICACTIVERn (RW): provide a Clear-active bit for each interrupt.
    // NOTE: These registers are associated with the same state. Reads are
    // identical and writing 1 sets or clears the associated register bit.
    active0: Vec<AtomicU32>,
    active: Vec<AtomicU32>,

    // GICD_IPRIORITYRn (RW): provide an 8-bit priority field for each interrupt.
    priority0: Vec<Vec<AtomicU32>>,
    priority: Vec<AtomicU32>,

    // GICD_ITARGETSRn (RW): provide an 8-bit CPU targets field for each interrupt.
    // NOTE: Registers 0 to 7 are RO.
    targets0: Vec<Vec<AtomicU32>>,
    targets: Vec<AtomicU32>,

    // GICD_ICFGRn (RW): provide a 2-bit Int_config field for each interrupt.
    // NOTE: Register 0 is RO.
    config: Vec<AtomicU32>,

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
    sgi_pending: Vec<Vec<AtomicU32>>,

    // Identification registers (RO).
    periph_id: Vec<AtomicU32>,
    component_id: Vec<AtomicU32>,
}

impl Distributor {

    pub fn new(num_nodes: usize) -> Self {
        let gic_dist = Self {
            num_nodes,

            control: AtomicU32::new(0),
            ic_type: AtomicU32::new(0),
            dist_ident: AtomicU32::new(0),

            // irq_group0 is one banked register per node.
            irq_group0: (0..num_nodes).map(|_| AtomicU32::new(0)).collect(),
            irq_group: (0..31).map(|_| AtomicU32::new(0)).collect(),

            // enable0  is one banked register per node.
            enable0: (0..num_nodes).map(|_| AtomicU32::new(0)).collect(),
            enable: (0..31).map(|_| AtomicU32::new(0)).collect(),

            // pending0  is one banked register per node.
            pending0: (0..num_nodes).map(|_| AtomicU32::new(0)).collect(),
            pending: (0..31).map(|_| AtomicU32::new(0)).collect(),

            // active0  is one banked register per node.
            active0: (0..num_nodes).map(|_| AtomicU32::new(0)).collect(),
            active: (0..31).map(|_| AtomicU32::new(0)).collect(),

            // priority0 is 8 banked registers for each node
            priority0: (0..num_nodes)
                .map(|_| (0..8).map(|_| AtomicU32::new(0)).collect())
                .collect(),
            priority: (0..247).map(|_| AtomicU32::new(0)).collect(),

            // targets0 is 8 banked registers for each node
            targets0: (0..num_nodes)
                .map(|_| (0..8).map(|_| AtomicU32::new(0)).collect())
                .collect(),
            targets: (0..247).map(|_| AtomicU32::new(0)).collect(),

            // TODO: The PPIs should be banked (i.e., config1)
            config: (0..64).map(|_| AtomicU32::new(0)).collect(),

            // sgi_pending is 4 banked registers for each node
            sgi_pending: (0..num_nodes)
                .map(|_| (0..4).map(|_| AtomicU32::new(0)).collect())
                .collect(),

            periph_id: (0..12).map(|_| AtomicU32::new(0)).collect(),
            component_id: (0..4).map(|_| AtomicU32::new(0)).collect(),
        };

        gic_dist.reset();
        gic_dist
    }

    // TODO: Return a Result.
    pub fn handle_write(&self, offset: usize, node_index: usize, val: VMFaultData) -> WriteAction {
        match val {
            VMFaultData::Word(val) => {
                let reg = GICDistRegWord::from_offset(offset);
                match reg {
                    GICDistRegWord::GICD_CTLR => {
                        // Set or clear the control register.
                        // If the state has changed, inform the vmm.
                        if val == 1 {
                            let prev = self.control.fetch_or(val, Ordering::SeqCst);
                            if prev == 0 {
                                // Identify newly enabled IRQs and check if any are
                                // pending and should be injected into CPUs.
                                // For newly enabled IRQs that are NOT pending, we tell
                                // the VMM to ack them in case an IRQ was signaled before
                                // we were paying attention...
                                // NOTE: We focus only on the current node_index
                                // and assume other nodes will enable and check
                                // their own interrupts when they come online.
                                // For SPIs, only one core is expected to ack anyway.
                                let mut to_inject: Vec<(IRQ, CPU)> = Vec::new();
                                let mut to_ack: Vec<(IRQ, CPU)> = Vec::new();
                                for irq in 0..1020 {
                                    if self.should_inject(irq, node_index) {
                                        to_inject.push((irq, node_index));
                                    } else if self.is_enabled(irq, node_index) {
                                        to_ack.push((irq, node_index));
                                    }
                                }

                                if to_inject.len() == 0 && to_ack.len() == 0 {
                                    return WriteAction::NoAction;
                                } else {
                                    return WriteAction::InjectAndAckIRQs((Some(to_inject), Some(to_ack)));
                                }
                            }
                        } else if val == 0 {
                            let prev = self.control.fetch_and(val, Ordering::SeqCst);
                            if prev == 1 {
                                return WriteAction::NoAction;
                            }
                        } else {
                            panic!("Unknown control register encoding 0{:x}", val);
                        }

                        // If the state hasn't changed, take no action.
                        return WriteAction::NoAction;
                    }
                    GICDistRegWord::GICD_TYPER => panic!("Writing to read only register {:?}", reg),
                    GICDistRegWord::GICD_IIDR => panic!("Writing to read only register {:?}", reg),
                    GICDistRegWord::GICD_IGROUPRn(reg_num) => {
                        // Set group registers.
                        // - NOTE: Register 0 is banked for each CPU.
                        let group_reg;
                        if reg_num == 0 {
                            group_reg = &self.irq_group0[node_index];
                        } else {
                            group_reg = &self.irq_group[reg_num - 1];
                        }
                        group_reg.store(val, Ordering::SeqCst);

                        // TODO: Action required if the group changes? C VMM does nothing.
                        return WriteAction::NoAction;
                    }
                    GICDistRegWord::GICD_ISENABLERn(reg_num) => {
                        // Set enable registers.
                        // - Writing 1 to an IRQ bit enables the IRQ.
                        // - Writing 0 to an IRQ bit has no effect.
                        // - NOTE: Register 0 is banked for each CPU.
                        if val == 0 {
                            return WriteAction::NoAction;
                        }

                        let enable_reg;
                        if reg_num == 0 {
                            enable_reg = &self.enable0[node_index];
                        } else {
                            enable_reg = &self.enable[reg_num - 1];
                        }
                        let prev = enable_reg.fetch_or(val, Ordering::SeqCst);

                        // Identify newly enabled IRQs and check if any are
                        // pending and should be injected into CPUs.
                        // For newly enabled IRQs that are NOT pending, we tell
                        // the VMM to ack them in case an IRQ was signaled before
                        // we were paying attention...
                        // NOTE: We focus only on the current node_index
                        // and assume other nodes will enable and check
                        // their own interrupts when they come online.
                        // For SPIs, only one core is expected to ack anyway.
                        let newly_enabled = val & !prev;
                        let mut to_inject: Vec<(IRQ, CPU)> = Vec::new();
                        let mut to_ack: Vec<(IRQ, CPU)> = Vec::new();
                        for i in biterate(newly_enabled) {
                            let irq = (usize::try_from(i).unwrap() + reg_num * 32) as IRQ;
                            if self.should_inject(irq, node_index) {
                                to_inject.push((irq, node_index));
                            } else {
                                to_ack.push((irq, node_index));
                            }
                        }

                        if to_inject.len() == 0 && to_ack.len() == 0 {
                            return WriteAction::NoAction;
                        } else {
                            return WriteAction::InjectAndAckIRQs((Some(to_inject), Some(to_ack)));
                        }
                    }
                    GICDistRegWord::GICD_ICENABLERn(reg_num) => {
                        // Clear enable registers.
                        // - Writing 1 to an IRQ bit disables the IRQ.
                        // - Writing 0 to an IRQ bit has no effect.
                        // - NOTE: Register 0 is banked for each CPU.
                        if val == 0 {
                            return WriteAction::NoAction;
                        }

                        let enable_reg;
                        if reg_num == 0 {
                            enable_reg = &self.enable0[node_index];
                        } else {
                            enable_reg = &self.enable[reg_num];
                        }
                        enable_reg.fetch_and(!val, Ordering::SeqCst);

                        return WriteAction::NoAction;
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
                            return WriteAction::NoAction;
                        }

                        let pending_reg;
                        if reg_num == 0 {
                            // IRQs 0->15 are SGIs and are RO.
                            // Writes are ignored.
                            if val & 0xFFFF != 0 {
                                return WriteAction::NoAction;
                            }
                            pending_reg = &self.pending0[node_index];
                        } else {
                            pending_reg = &self.pending[reg_num - 1];
                        }
                        let prev = pending_reg.fetch_or(val, Ordering::SeqCst);

                        // Identify newly pending IRQs and check if any are
                        // not active and should be injected into CPUs.
                        // NOTE: We focus only on the current node_index
                        // as either the write was to a banked register or
                        // to an SPI, for which only one core is expected
                        // to ack anyway.
                        let newly_pending = val & !prev;
                        let mut to_inject: Vec<(IRQ, CPU)> = Vec::new();
                        for i in biterate(newly_pending) {
                            let irq = (usize::try_from(i).unwrap() + reg_num * 32) as IRQ;
                            if self.should_inject(irq, node_index) {
                                to_inject.push((irq, node_index));
                            }
                        }
                        if to_inject.len() == 0 {
                            return WriteAction::NoAction;
                        } else {
                            return WriteAction::InjectAndAckIRQs((Some(to_inject), None));
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
                            return WriteAction::NoAction;
                        }

                        let pending_reg;
                        if reg_num == 0 {
                            // IRQs 0->15 are SGIs and are RO.
                            // Writes are ignored.
                            if val & 0xFFFF != 0 {
                                panic!("Writing to read only register {:?}", reg);
                            }
                            pending_reg = &self.pending0[node_index];
                        } else {
                            pending_reg  = &self.pending[reg_num - 1];
                        }
                        pending_reg.fetch_and(!val, Ordering::SeqCst);

                        return WriteAction::NoAction;
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
                            return WriteAction::NoAction;
                        }

                        let active_reg;
                        if reg_num == 0 {
                            active_reg = &self.active0[node_index];
                        } else {
                            active_reg = &self.active[reg_num - 1];
                        }
                        active_reg.fetch_or(val, Ordering::SeqCst);

                        return WriteAction::NoAction;
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
                            return WriteAction::NoAction;
                        }

                        let active_reg;
                        if reg_num == 0 {
                            active_reg = &self.active0[node_index];
                        } else {
                            active_reg  = &self.active[reg_num - 1];
                        }
                        active_reg.fetch_and(!val, Ordering::SeqCst);

                        return WriteAction::NoAction;
                    }
                    GICDistRegWord::GICD_IPRIORITYRn(reg_num) => {
                        // Set priority registers.
                        // - Each IRQ has an 8 bit priority field.
                        // - This logic block writes an entire word, including
                        //   priority fields for four IRQs.
                        // - NOTE: Registers 0 to 7 banked for each CPU.
                        let priority_reg;
                        if reg_num < 8 {
                            priority_reg = &self.priority0[node_index][reg_num];
                        } else {
                            priority_reg = &self.priority[reg_num - 8];
                        }
                        priority_reg.store(val, Ordering::SeqCst);

                        return WriteAction::NoAction;
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
                            // TODO: Should writing to an RO register panic?
                            panic!("Writing to a read-only GIC register {:?}", reg);
                            // return WriteAction::NoAction;
                        } else {
                            targets_reg = &self.targets[reg_num - 8];
                        }
                        let prev = targets_reg.swap(val, Ordering::SeqCst);

                        let new_cpus = val & !prev;
                        if new_cpus == 0 {
                            return WriteAction::NoAction;
                        }

                        // Iterate through the four IRQs and the eight CPUs
                        // in the register.  If the IRQ is pending for that CPU
                        // and not yet active, add it to a vector of IRQs to inject.
                        // For newly targeted IRQs that are NOT pending, we tell
                        // the VMM to ack them in case an IRQ was signaled before
                        // we were paying attention...
                        // NOTE: We focus only on the current node_index
                        // and assume other nodes will check
                        // their own interrupts when they come online.
                        // For SPIs, only one core is expected to ack anyway.
                        let mut to_inject: Vec<(IRQ, CPU)> = Vec::new();
                        let mut to_ack: Vec<(IRQ, CPU)> = Vec::new();
                        let base_irq = (reg_num * 4) as IRQ;
                        for irq in base_irq..base_irq + 4 {
                            if self.should_inject(irq, node_index) {
                                to_inject.push((irq, node_index));
                            } else {
                                to_ack.push((irq, node_index));
                            }
                        }

                        if to_inject.len() == 0 && to_ack.len() == 0 {
                            return WriteAction::NoAction;
                        } else {
                            return WriteAction::InjectAndAckIRQs((Some(to_inject), Some(to_ack)));
                        }
                    }
                    GICDistRegWord::GICD_ICFGRn(reg_num) => {
                        // Set trigger configuration registers.
                        // - Each IRQ has a 2 bit field identifying if the IRQ is
                        //   level or edge triggered.
                        // - This logic block writes an entire word, including
                        //   config fields for eight IRQs.
                        // - SGI configuration fields are RO.
                        // - An IRQ must be disabled to change its config, or
                        //   the GIC behaviour is UNPREDICTABLE.

                        let config_reg;
                        if reg_num == 0 {
                            // SGI IRQ #s are 0-15 and fill the 0th register.
                            // As these are RO, writing has no effect.
                            return WriteAction::NoAction;
                        } else {
                            config_reg = &self.config[reg_num];
                        }
                        config_reg.store(val, Ordering::SeqCst);
                        return WriteAction::NoAction;
                    }
                    GICDistRegWord::GICD_NSACRn(reg_num) => {
                        // Set non-secure access control registers.
                        // - Not implemented.  The VM is not in Secure mode.
                        panic!("Illegal attempt to modify non-secure access \
                               control register");
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
                            return WriteAction::NoAction;
                        }

                        if to_inject.len() == 0 {
                            return WriteAction::NoAction;
                        } else {
                            return WriteAction::InjectAndAckIRQs((Some(to_inject), None));
                        }
                    }
                    GICDistRegWord::GICD_CPENDSGIRn(reg_num) => {
                        // Clear SGI pending registers.
                        // - Writing 1 to an IRQ bit clears the pending state.
                        // - Writing 0 to an IRQ bit has no effect.
                        // - NOTE: Registers are banked for each CPU.
                        if val == 0 {
                            return WriteAction::NoAction;
                        }

                        let sgi_pending_reg;
                        sgi_pending_reg  = &self.sgi_pending[node_index][reg_num];
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

                        return WriteAction::NoAction;
                    }
                    GICDistRegWord::GICD_SPENDSGIRn(reg_num) => {
                        // Set SGI pending registers.
                        // - Writing 1 to an IRQ bit sets the pending state.
                        // - Writing 0 to an IRQ bit has no effect.
                        // - NOTE: All registers are banked for each CPU.
                        if val == 0 {
                            return WriteAction::NoAction;
                        }

                        let sgi_pending_reg;
                        sgi_pending_reg  = &self.sgi_pending[node_index][reg_num];
                        let prev = sgi_pending_reg.fetch_or(val, Ordering::SeqCst);

                        let base_irq = (reg_num * 4) as IRQ;

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

                        // Identify newly pending IRQs in the four IRQs in the
                        // register, and check if any are not active and should
                        // be injected into CPUs.
                        let mut to_inject: Vec<(IRQ, CPU)> = Vec::new();
                        for irq in base_irq..base_irq + 4 {
                            if self.should_inject(irq, node_index) {
                                to_inject.push((irq, node_index));
                            }
                        }
                        if to_inject.len() == 0 {
                            return WriteAction::NoAction;
                        } else {
                            return WriteAction::InjectAndAckIRQs((Some(to_inject), None));
                        }
                    }
                    GICDistRegWord::ICPIDRn(reg_num) => panic!("Writing to read only register {:?}", reg),
                    GICDistRegWord::ICCIDRn(reg_num) => panic!("Writing to read only register {:?}", reg),
                    _ => panic!("Writing to an undefined register {:?}", reg)
                }
            }
            VMFaultData::Byte(val) => {
                let reg = GICDistRegByte::from_offset(offset);
                panic!("Byte-accessible writes to GIC not yet implemented.");
                // match reg {
                //     _ => panic!("Why are we writing bytes to the GIC?")
                // }
            }
            _ => panic!("Writes to GIC distributor registers must by byte- or word-aligned.")
        }
    }

    // TODO: Return a Result.
    // Will always return a VMFaultData of width VMFaultWidth
    pub fn handle_read(&self, offset: usize, node_index: usize, width: VMFaultWidth) -> (VMFaultData, ReadAction) {
        match width {
            VMFaultWidth::Word => {
                let reg = GICDistRegWord::from_offset(offset);
                match reg {
                    GICDistRegWord::GICD_CTLR => {
                        // Read the control register.
                        let val = self.control.load(Ordering::SeqCst);
                        return (VMFaultData::Word(val), ReadAction::NoAction);
                    }
                    GICDistRegWord::GICD_TYPER => {
                        // Read the interrupt controller type register.
                        let val = self.ic_type.load(Ordering::SeqCst);
                        return (VMFaultData::Word(val), ReadAction::NoAction);
                    }
                    GICDistRegWord::GICD_IIDR => {
                        // Read the implementer identification register.
                        let val = self.dist_ident.load(Ordering::SeqCst);
                        return (VMFaultData::Word(val), ReadAction::NoAction);
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
                        return (VMFaultData::Word(val), ReadAction::NoAction);
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
                        return (VMFaultData::Word(val), ReadAction::NoAction);
                    }
                    GICDistRegWord::GICD_ISPENDRn(reg_num) |
                        GICDistRegWord::GICD_ICPENDRn(reg_num) => {
                        // Read pending registers.
                        // NOTE: Register 0 is banked for each CPU.
                        // TODO: SGI should read (or mirror) status from SGI pending registers.
                        let pending_reg;
                        if reg_num == 0 {
                            pending_reg = &self.pending0[node_index];
                        } else {
                            pending_reg = &self.pending[reg_num - 1];
                        }
                        let val = pending_reg.load(Ordering::SeqCst);
                        return (VMFaultData::Word(val), ReadAction::NoAction);
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
                        return (VMFaultData::Word(val), ReadAction::NoAction);
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
                        return (VMFaultData::Word(val), ReadAction::NoAction);
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
                        return (VMFaultData::Word(val), ReadAction::NoAction);
                    }
                    GICDistRegWord::GICD_ICFGRn(reg_num) => {
                        // Read trigger configuration registers.
                        let config;
                        config = &self.config[reg_num];
                        let val = config.load(Ordering::SeqCst);
                        return (VMFaultData::Word(val), ReadAction::NoAction);
                    }
                    GICDistRegWord::GICD_NSACRn(reg_num) => {
                        // Read non-secure access control registers.
                        // - Not implemented.  The VM is not in Secure mode.
                        panic!("Illegal attempt to read non-secure access \
                               control register");
                    }
                    GICDistRegWord::GICD_SGIR => panic!("Reading from a write only register {:?}", reg),
                    GICDistRegWord::GICD_CPENDSGIRn(reg_num) |
                        GICDistRegWord::GICD_SPENDSGIRn(reg_num) => {
                        // Read sgi pending registers.
                        // NOTE: Registers are banked for each CPU.
                        let sgi_pending_reg;
                        sgi_pending_reg = &self.sgi_pending[node_index][reg_num];
                        let val = sgi_pending_reg.load(Ordering::SeqCst);
                        return (VMFaultData::Word(val), ReadAction::NoAction);
                    }
                    GICDistRegWord::ICPIDRn(reg_num) => {
                        // Read peripheral ID registers.
                        let periph_id_reg;
                        periph_id_reg = &self.periph_id[reg_num];
                        let val = periph_id_reg.load(Ordering::SeqCst);
                        return (VMFaultData::Word(val), ReadAction::NoAction);
                    }
                    GICDistRegWord::ICCIDRn(reg_num) => {
                        // Read component ID registers.
                        let component_id_reg;
                        component_id_reg = &self.component_id[reg_num];
                        let val = component_id_reg.load(Ordering::SeqCst);
                        return (VMFaultData::Word(val), ReadAction::NoAction);
                    }
                    _ => panic!("Writing to an undefined register {:?}", reg)
                }
            }
            VMFaultWidth::Byte => {
                let reg = GICDistRegByte::from_offset(offset);
                panic!("Byte-accessible reads from GIC not yet implemented.");
                // match reg {
                //     _ => panic!("Why are we reading bytes from the GIC?")
                // }
            }
            _ => panic!("Reads from GIC distributor registers must by byte- or word-aligned.")
        }
    }

    fn should_inject(&self, irq: IRQ, cpu: CPU) -> bool {
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

    fn is_target(&self, irq: IRQ, cpu: CPU) -> bool {
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

    fn clear_pending(&self, irq: IRQ, cpu: CPU) -> Result<(), IRQError> {
        if usize::try_from(cpu).unwrap() >= self.num_nodes {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidCPU(cpu) });
        }

        let reg;
        if irq < 32 {
            reg = &self.pending0[cpu];
        } else {
            reg = &self.pending[irq / 32 - 1];
        }

        let shift = irq % 32;
        let val: u32 = 1 << shift;
        reg.fetch_and(!val, Ordering::SeqCst);

		Ok(())
    }

    fn set_pending(&self, irq: IRQ, cpu: CPU) -> Result<(), IRQError> {
        if usize::try_from(cpu).unwrap() >= self.num_nodes {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidCPU(cpu) });
        }

        let reg;
        if irq < 32 {
            reg = &self.pending0[cpu];
        } else {
            reg = &self.pending[irq / 32 - 1];
        }

        let shift = irq % 32;
        let val: u32 = 1 << shift;
        reg.fetch_or(val, Ordering::SeqCst);

		Ok(())
    }

    fn set_sgi_pending(&self, irq: IRQ, source_cpu: CPU, target_cpu: CPU) -> Result<(), IRQError> {
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
        let reg = &self.sgi_pending[target_cpu][reg_num];

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

    fn clear_sgi_pending(&self, irq: IRQ, source_cpu: CPU, target_cpu: CPU) -> Result<(), IRQError> {
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
        let reg = &self.sgi_pending[target_cpu][reg_num];

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

    fn clear_active(&self, irq: IRQ, cpu: CPU) -> Result<(), IRQError> {
        if usize::try_from(cpu).unwrap() >= self.num_nodes {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidCPU(cpu) });
        }

        let reg;
        if irq < 32 {
            reg = &self.active0[cpu];
        } else {
            reg = &self.active[irq / 32 - 1];
        }

        let shift = irq % 32;
        let val: u32 = 1 << shift;
        reg.fetch_and(!val, Ordering::SeqCst);

		Ok(())
    }

    fn set_active(&self, irq: IRQ, cpu: CPU) -> Result<(), IRQError> {
        if usize::try_from(cpu).unwrap() >= self.num_nodes {
            return Err(IRQError{ irq_error_type: IRQErrorType::InvalidCPU(cpu) });
        }

        let reg;
        if irq < 32 {
            reg = &self.active0[cpu];
        } else {
            reg = &self.active[irq / 32 - 1];
        }

        let shift = irq % 32;
        let val: u32 = 1 << shift;
        reg.fetch_or(val, Ordering::SeqCst);

		Ok(())
    }

    pub fn handle_spi(&self, irq: IRQ) -> SPIAction {
        // SPIs are shared, so we provide a dummy CPU value.
        let cpu = 0 as CPU;
        self.set_pending(irq, cpu).unwrap();
        if self.should_inject(irq, cpu) {
            return SPIAction::InjectIRQ;
        } else {
            return SPIAction::NoAction;
        }
    }

    pub fn handle_ppi(&self, irq: IRQ, node_index: usize) -> PPIAction {
        let cpu = node_index as CPU;
        self.set_pending(irq, cpu).unwrap();
        if self.should_inject(irq, cpu) {
            return PPIAction::InjectIRQ;
        } else {
            return PPIAction::NoAction;
        }
    }

    pub fn handle_sgi(&self, irq: IRQ, target_cpu: usize) -> SGIAction {
        // seL4 API does not give us source cpu information for an SGI,
        // so we just default to 0.
        self.set_sgi_pending(irq, 0, target_cpu).unwrap();
        if self.should_inject(irq, target_cpu as CPU) {
            return SGIAction::InjectIRQ;
        } else {
            return SGIAction::NoAction;
        }
    }

    // The seL4 API does not appear to distinguish between an ack and an
    // eoi.  I.e., there is no expectation of a transition from pending->active.
    // Therefore, we treat an ack like an eoi and clear the pending state, but
    // do not set the active state.
    pub fn handle_ack(&self, irq: IRQ, node_index: usize) -> AckAction {
        let cpu = node_index as CPU;
        if irq < 16 {
            self.clear_sgi_pending(irq, 0, cpu);
        } else {
            self.clear_pending(irq, cpu).unwrap();
        }
        AckAction::NoAction
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
    pub fn reset(&self) {
        self.ic_type.store(0x0000fce7, Ordering::SeqCst); // RO
        self.dist_ident.store(0x0200043b, Ordering::SeqCst); // RO

        // Reset per-CPU enable and _clr registers
        for i in 0..self.num_nodes {
            self.enable0[i].store(0x0000ffff, Ordering::SeqCst); // 16-bit RO
        }

        // Reset value depends on GIC configuration
        self.config[0].store(0xaaaaaaaa, Ordering::SeqCst); // RO
        self.config[1].store(0x55540000, Ordering::SeqCst);
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
        self.config[14].store(0x55555555, Ordering::SeqCst);
        self.config[15].store(0x55555555, Ordering::SeqCst);

        // Configure per-CPU SGI/PPI target registers
        // 1. Reset each register to 0x0.
        // 2. Iterate through each CPU and its 8 banked registers.
        // 3. Bitwise-or a 1 in the CPU target field for each interrupt.
        // e.g., for CPU1, targets0[1][j] = 00000010 00000010 00000010 00000010
        for (idx, bank) in self.targets0.iter().enumerate() {
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
        for target in self.targets.iter() {
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

// Used to identify a register number.  No register type exceeds 255 registers.
type IRQRegNum = usize;

// Used to identify a byte offset in a 32 bit register.
type IRQRegByte = usize;

// Enumerate each of the GIC Distributor registers that are word-accessible
#[derive(Debug)]
#[allow(non_camel_case_types)]
enum GICDistRegWord {
    GICD_CTLR,
    GICD_TYPER,
    GICD_IIDR,
    GICD_IGROUPRn(IRQRegNum),
    GICD_ISENABLERn(IRQRegNum),
    GICD_ICENABLERn(IRQRegNum),
    GICD_ISPENDRn(IRQRegNum),
    GICD_ICPENDRn(IRQRegNum),
    GICD_ISACTIVERn(IRQRegNum),
    GICD_ICACTIVERn(IRQRegNum),
    GICD_IPRIORITYRn(IRQRegNum),
    GICD_ITARGETSRn(IRQRegNum),
    GICD_ICFGRn(IRQRegNum),
    GICD_NSACRn(IRQRegNum),
    GICD_SGIR,
    GICD_CPENDSGIRn(IRQRegNum),
    GICD_SPENDSGIRn(IRQRegNum),
    ICCIDRn(IRQRegNum),
    ICPIDRn(IRQRegNum),
}

impl GICDistRegWord {
    fn from_offset(offset: usize) -> Self {
        match offset {
            0x000 => GICDistRegWord::GICD_CTLR,
            0x004 => GICDistRegWord::GICD_TYPER,
            0x008 => GICDistRegWord::GICD_IIDR,
            0x080..=0x0FC => GICDistRegWord::GICD_IGROUPRn(calc_reg_num(offset, 0x080)),
            0x100..=0x17C => GICDistRegWord::GICD_ISENABLERn(calc_reg_num(offset, 0x100)),
            0x180..=0x1FC => GICDistRegWord::GICD_ICENABLERn(calc_reg_num(offset, 0x180)),
            0x200..=0x27C => GICDistRegWord::GICD_ISPENDRn(calc_reg_num(offset, 0x200)),
            0x280..=0x2FC => GICDistRegWord::GICD_ICPENDRn(calc_reg_num(offset, 0x280)),
            0x300..=0x37C => GICDistRegWord::GICD_ISACTIVERn(calc_reg_num(offset, 0x300)),
            0x380..=0x3FC => GICDistRegWord::GICD_ICACTIVERn(calc_reg_num(offset, 0x380)),
            0x400..=0x7F8 => GICDistRegWord::GICD_IPRIORITYRn(calc_reg_num(offset, 0x400)),
            0x800..=0xBF8 => GICDistRegWord::GICD_ITARGETSRn(calc_reg_num(offset, 0x800)),
            0xC00..=0xCFC => GICDistRegWord::GICD_ICFGRn(calc_reg_num(offset, 0xC00)),
            0xE00..=0xEFC => GICDistRegWord::GICD_NSACRn(calc_reg_num(offset, 0xE00)),
            0xF00 => GICDistRegWord::GICD_SGIR,
            0xF10..=0xF1C => GICDistRegWord::GICD_CPENDSGIRn(calc_reg_num(offset, 0xF10)),
            0xF20..=0xF2C => GICDistRegWord::GICD_SPENDSGIRn(calc_reg_num(offset, 0xF20)),
            0xFD0..=0xFEC => GICDistRegWord::ICPIDRn(calc_reg_num(offset, 0xFD0)),
            0xFF0..=0xFFC => GICDistRegWord::ICCIDRn(calc_reg_num(offset, 0xFF0)),
            _ => panic!("Undefined register offset {:x}", offset)
        }
    }
}

// Enumerate each of the GIC Distributor registers that are byte-accessible
#[derive(Debug)]
#[allow(non_camel_case_types)]
enum GICDistRegByte {
    GICD_IPRIORITYRn(IRQRegNum, IRQRegByte),
    GICD_ITARGETSRn(IRQRegNum, IRQRegByte),
    GICD_CPENDSGIRn(IRQRegNum, IRQRegByte),
    GICD_SPENDSGIRn(IRQRegNum, IRQRegByte),
}

impl GICDistRegByte {
    fn from_offset(offset: usize) -> Self {
        match offset {
            0x400..=0x7F8 => GICDistRegByte::GICD_IPRIORITYRn(
                calc_reg_num(offset, 0x400),
                calc_reg_byte_offset(offset, 0x400)
                ),
            0x800..=0xBF8 => GICDistRegByte::GICD_ITARGETSRn(
                calc_reg_num(offset, 0x800),
                calc_reg_byte_offset(offset, 0x800)
                ),
            0xF10..=0xF1C => GICDistRegByte::GICD_CPENDSGIRn(
                calc_reg_num(offset, 0xF10),
                calc_reg_byte_offset(offset, 0xF10)
                ),
            0xF20..=0xF2C => GICDistRegByte::GICD_SPENDSGIRn(
                calc_reg_num(offset, 0xF20),
                calc_reg_byte_offset(offset, 0xF20)
                ),
            _ => panic!("Undefined register offset {:x}", offset)
        }
    }
}

fn calc_reg_num(offset: usize, base: usize) -> IRQRegNum {
    let reg_num = (offset - base) / mem::size_of::<u32>();
    assert!(reg_num < 256);
    reg_num
}

fn calc_reg_byte_offset(offset: usize, base: usize) -> IRQRegByte {
    let reg_byte = (offset - base) % mem::size_of::<u32>();
    assert!(reg_byte < mem::size_of::<u32>());
    reg_byte
}

// TODO: Is this necessary anymore?
// impl Deref for Distributor {
//     type Target = DistributorRegisterBlock;

//     fn deref(&self) -> &Self::Target {
//         unsafe {
//             &*self.ptr()
//         }
//     }
// }

fn irq_idx(irq: IRQ) -> usize {
    irq / 32
}

fn irq_bit(irq: IRQ) -> u32 {
    1 << (irq % 32)
}

// Converts bits in an IRQ register to a vector if IRQ values.
fn reg_word_to_irqs(reg_num: IRQRegNum, irq_bits: u32) -> Vec<IRQ> {
    let mut irqs: Vec<IRQ> = Vec::new();
    for i in biterate(irq_bits) {
        let irq_num = (i as usize) + 32 * reg_num;
        irqs.push(irq_num as IRQ)
    }
    irqs
}


// #[derive(Debug)]
// pub enum Action {
//     ReadOnly,
//     Passthru,
//     Enable,
//     EnableSet,
//     EnableClr,
//     PendingSet,
//     PendingClr,
//     SGI,
//     SGIPendingSet,
//     SGIPendingClear,
// }

// impl Action {
//     pub fn at(offset: usize) -> Self {
//         // The only fields we care about are enable/clr
//         // We have 2 options for other registers:
//         //  a) ignore writes and hope the VM acts appropriately (ReadOnly)
//         //  b) allow write access so the VM thinks there is no problem,
//         //     but do not honour them (Passthru)
//         match offset {
//             0x000..0x004 => Action::Enable, // enable
//             0x080..0x100 => Action::Passthru, // security
//             0x100..0x180 => Action::EnableSet, // enable
//             0x180..0x200 => Action::EnableClr, // enable_clr
//             0x200..0x280 => Action::PendingSet, // pending_set
//             0x280..0x300 => Action::PendingClr, // pending_clr
//             0xC00..0xD00 => Action::Passthru, // config
//             0xF00..0xF04 => Action::SGI, // sgi
//             0xF10..0xF20 => Action::SGIPendingClear, // sgi_pending_clr
//             0xF20..0xF30 => Action::SGIPendingSet, // sgi_pending_set
//             _ => Action::ReadOnly,
//         }
//     }
// }
