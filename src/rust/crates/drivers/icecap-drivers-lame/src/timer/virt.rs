use core::ops::Deref;
use tock_registers::{registers::{ReadOnly, ReadWrite}, interfaces::{Readable, Writeable}, register_structs};
use crate::timer::TimerDevice;

register_structs! {
    pub QemuTimerRegisterBlock {
        (0x000 => freq: ReadOnly<u32>),
        (0x004 => enable: ReadWrite<u32>),
        (0x008 => count: ReadOnly<u64>),
        (0x010 => compare: ReadWrite<u64>),
        (0x018 => @END),
    }
}

pub struct QemuTimerDevice {
    base_addr: usize,
}

impl QemuTimerDevice {

    pub fn new(base_addr: usize) -> Self {
        Self {
            base_addr,
        }
    }

    fn ptr(&self) -> *const QemuTimerRegisterBlock {
        self.base_addr as *const _
    }

}

impl Deref for QemuTimerDevice {
    type Target = QemuTimerRegisterBlock;

    fn deref(&self) -> &Self::Target {
        unsafe {
            &*self.ptr()
        }
    }
}

impl TimerDevice for QemuTimerDevice {

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

    fn clear_interrupt(&self) {
    }

}
