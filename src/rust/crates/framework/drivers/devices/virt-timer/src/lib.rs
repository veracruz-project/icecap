#![no_std]

use core::ops::Deref;

use tock_registers::{
    interfaces::{Readable, Writeable},
    register_structs,
    registers::{ReadOnly, ReadWrite},
};

use icecap_driver_interfaces::TimerDevice;

register_structs! {
    pub VirtTimerRegisterBlock {
        (0x000 => freq: ReadOnly<u32>),
        (0x004 => enable: ReadWrite<u32>),
        (0x008 => count: ReadOnly<u64>),
        (0x010 => compare: ReadWrite<u64>),
        (0x018 => @END),
    }
}

pub struct VirtTimerDevice {
    base_addr: usize,
}

impl VirtTimerDevice {
    pub fn new(base_addr: usize) -> Self {
        Self { base_addr }
    }

    fn ptr(&self) -> *const VirtTimerRegisterBlock {
        self.base_addr as *const _
    }
}

impl Deref for VirtTimerDevice {
    type Target = VirtTimerRegisterBlock;

    fn deref(&self) -> &Self::Target {
        unsafe { &*self.ptr() }
    }
}

impl TimerDevice for VirtTimerDevice {
    fn get_freq(&self) -> u32 {
        self.freq.get()
    }

    fn set_enable(&self, enabled: bool) {
        self.enable.set(if enabled { 1 } else { 0 })
    }

    fn get_count(&self) -> u64 {
        self.count.get()
    }

    fn set_compare(&self, compare: u64) -> bool {
        self.compare.set(compare);
        true
    }

    fn clear_interrupt(&self) {}
}
