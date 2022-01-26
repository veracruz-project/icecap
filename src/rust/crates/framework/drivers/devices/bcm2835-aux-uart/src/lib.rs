#![no_std]
#![allow(dead_code)]

use core::ops::Deref;

use tock_registers::{
    interfaces::{Readable, Writeable},
    register_structs,
    registers::ReadWrite,
};

use icecap_core::prelude::*;
use icecap_driver_interfaces::SerialDevice;

// TODO use structured bitfields

const MU_LSR_TXIDLE: u32 = 1 << 6;
const MU_LSR_DATAREADY: u32 = 1 << 0;

register_structs! {
    #[allow(non_snake_case)]
    pub Bcm2835AuxUartRegisterBlock {
        (0x000 => _reserved0),
        (0x040 => IO: ReadWrite<u8>),
        (0x041 => _reserved1),
        (0x044 => IER: ReadWrite<u32>),
        (0x048 => _reserved2),
        (0x054 => LSR: ReadWrite<u32>),
        (0x058 => @END),
    }
}

pub struct Bcm2835AuxUartDevice {
    base_addr: usize,
}

impl Bcm2835AuxUartDevice {
    pub fn new(base_addr: usize) -> Self {
        Self { base_addr }
    }

    fn ptr(&self) -> *const Bcm2835AuxUartRegisterBlock {
        self.base_addr as *const _
    }

    pub fn init(&self) {
        self.handle_interrupt()
    }
}

impl Deref for Bcm2835AuxUartDevice {
    type Target = Bcm2835AuxUartRegisterBlock;

    fn deref(&self) -> &Self::Target {
        unsafe { &*self.ptr() }
    }
}

impl SerialDevice for Bcm2835AuxUartDevice {
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

    fn handle_interrupt(&self) {
        self.IER.set(5);
    }
}
