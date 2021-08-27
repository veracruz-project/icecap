use icecap_std::prelude::*;
use core::ops::Deref;
use tock_registers::{registers::{ReadOnly, ReadWrite}, interfaces::{Readable, Writeable, ReadWriteable}, register_bitfields, register_structs};
use crate::device::SerialDevice;

// TODO use structured bitfields

const PL011_UARTFR_TXFF: u32 = 1 << 5;
const PL011_UARTFR_RXFE: u32 = 1 << 4;

register_structs! {
    #[allow(non_snake_case)]
    pub RegisterBlock {
        (0x000 => DR: ReadWrite<u8>),
        (0x001 => _reserved0),
        (0x018 => FR: ReadWrite<u32>),
        (0x01c => _reserved1),
        (0x038 => IMSC: ReadWrite<u32>),
        (0x03c => _reserved2),
        (0x044 => ICR: ReadWrite<u32>),
        (0x048 => @END),
    }
}

pub struct Device {
    base_addr: usize,
}

impl Device {

    pub fn new(base_addr: usize) -> Self {
        Self {
            base_addr,
        }
    }

    fn ptr(&self) -> *const RegisterBlock {
        self.base_addr as *const _
    }

    pub fn init(&self) {
        self.IMSC.set(0x50);
    }

}

impl Deref for Device {
    type Target = RegisterBlock;

    fn deref(&self) -> &Self::Target {
        unsafe {
            &*self.ptr()
        }
    }
}

impl SerialDevice for Device {

    fn put_char(&self, c: u8) {
        // TODO queue rather than wait
        loop {
            if self.FR.get() & PL011_UARTFR_TXFF == 0 {
                break
            }
        }
        self.DR.set(c)
    }

    fn get_char(&self) -> Option<u8> {
        match self.FR.get() & PL011_UARTFR_RXFE {
            0 => Some(self.DR.get()),
            _ => None,
        }
    }

    fn handle_irq(&self) {
        self.ICR.set(0x7f0);
    }

}
