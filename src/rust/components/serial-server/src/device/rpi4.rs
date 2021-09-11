use icecap_std::prelude::*;
use core::ops::Deref;
use tock_registers::{registers::ReadWrite, interfaces::{Readable, Writeable}, register_structs};
use crate::device::SerialDevice;

// TODO use structured bitfields

const MU_LSR_TXIDLE: u32 = 1 << 6;
const MU_LSR_DATAREADY: u32 = 1 << 0;

register_structs! {
    #[allow(non_snake_case)]
    pub RegisterBlock {
        (0x000 => _reserved0),
        (0x040 => IO: ReadWrite<u8>),
        (0x041 => _reserved1),
        (0x044 => IER: ReadWrite<u32>),
        (0x048 => _reserved2),
        (0x054 => LSR: ReadWrite<u32>),
        (0x058 => @END),
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
        self.handle_irq()
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
        // loop {
        //     if self.LSR.get() & MU_LSR_TXIDLE != 0 {
        //         break
        //     }
        // }
        // self.IO.set(c);

        // HACK
        sel4::debug_put_char(c)
    }

    fn get_char(&self) -> Option<u8> {
        match self.LSR.get() & MU_LSR_DATAREADY {
            0 => None,
            _ => Some(self.IO.get()),
        }
    }

    fn handle_irq(&self) {
        self.IER.set(5);
    }

}
