#![allow(dead_code)]

use core::fmt;

use crate::distributor::{IRQ, CPU};

pub(crate) enum IRQErrorType {
    InvalidCPU(CPU),
    InvalidIRQ(IRQ),
    InvalidIrqCpu((IRQ, CPU)),
    InvalidRegisterWrite,
    InvalidRegisterRead,
}

#[derive(Fail)]
pub struct IRQError {
    pub(crate) irq_error_type: IRQErrorType,
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
            IRQErrorType::InvalidCPU(cpu) => {
                write!(f, "Accessing IRQ state for an invalid CPU: {}", cpu)
            }
            IRQErrorType::InvalidIRQ(irq) => {
                write!(f, "Unknown IRQ: {}", irq)
            }
            IRQErrorType::InvalidIrqCpu((irq, cpu)) => {
                write!(f, "Invalid IRQ {} for given CPU {}", irq, cpu)
            }
            IRQErrorType::InvalidRegisterWrite => {
                write!(f, "Invalid register write operation")
            }
            IRQErrorType::InvalidRegisterRead => {
                write!(f, "Invalid register read operation")
            }
        }
    }
}

impl fmt::Debug for IRQError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self.irq_error_type {
            IRQErrorType::InvalidCPU(cpu) => {
                write!(f, "Accessing IRQ state for an invalid CPU: {}", cpu)
            }
            IRQErrorType::InvalidIRQ(irq) => {
                write!(f, "Unknown IRQ: {}", irq)
            }
            IRQErrorType::InvalidIrqCpu((irq, cpu)) => {
                write!(f, "Invalid IRQ {} for given CPU {}", irq, cpu)
            }
            IRQErrorType::InvalidRegisterWrite => {
                write!(f, "Invalid register write operation")
            }
            IRQErrorType::InvalidRegisterRead => {
                write!(f, "Invalid register read operation")
            }
        }
    }
}
