#![no_std]

use core::ops::Deref;

use tock_registers::{
    interfaces::{Readable, Writeable},
    register_structs,
    registers::{ReadOnly, ReadWrite, WriteOnly},
};

use icecap_core::prelude::*;
use icecap_driver_interfaces::{TimerDevice, MHZ};

const MATCH_COUNT: usize = 4;
const FREQ: u64 = 1 * MHZ;

register_structs! {
    pub BcmSystemTimerRegisterBlock {
        (0x000 => ctrl: WriteOnly<u32>),
        (0x004 => counter_lo: ReadWrite<u32>),
        (0x008 => counter_hi: ReadOnly<u32>),
        (0x00c => compare: [ReadWrite<u32>; MATCH_COUNT]),
        (0x01c => @END),
    }
}

pub struct BcmSystemTimerDevice {
    base_addr: usize,
    match_ix: usize,
}

impl BcmSystemTimerDevice {
    pub fn new(base_addr: usize) -> Self {
        Self {
            base_addr,
            // NOTE Don't use compare 0 or 2, as they overlap with GPU IRQs.
            match_ix: 1,
        }
    }

    fn ptr(&self) -> *const BcmSystemTimerRegisterBlock {
        self.base_addr as *const _
    }

    fn get_count_split(&self) -> (u32, u32) {
        let hi_0 = self.counter_hi.get();
        let lo_0 = self.counter_lo.get();
        let hi = self.counter_hi.get();
        let lo = if hi_0 == hi {
            lo_0
        } else {
            self.counter_lo.get()
        };
        (hi, lo)
    }
}

impl Deref for BcmSystemTimerDevice {
    type Target = BcmSystemTimerRegisterBlock;

    fn deref(&self) -> &Self::Target {
        unsafe { &*self.ptr() }
    }
}

impl TimerDevice for BcmSystemTimerDevice {
    fn get_freq(&self) -> u32 {
        FREQ as u32
    }

    fn set_enable(&self, _enabled: bool) {}

    fn get_count(&self) -> u64 {
        let (hi, lo) = self.get_count_split();
        join_reg(hi, lo)
    }

    // TODO
    fn set_compare(&self, compare: u64) -> bool {
        let (compare_hi, compare_lo) = split_reg(compare);
        {
            // This device has 32-bit registers and a 1 MHz counter so it is not
            // possible to schedule an interrupt in more than about 70 minutes.
            let (hi, lo) = self.get_count_split();
            if !((compare_hi == hi && compare_lo > lo) || (compare_hi == hi + 1 && compare_lo < lo))
            {
                debug_println!(
                    "set_compare: 0x{:x} 0x{:x} 0x{:x} 0x{:x}",
                    compare_hi,
                    compare_lo,
                    hi,
                    lo
                );
            }
        }
        self.compare[self.match_ix].set(compare_lo);
        let count_lo = self.counter_lo.get();
        return compare_lo >= count_lo;
    }

    fn clear_interrupt(&self) {
        self.ctrl.set(1 << self.match_ix);
    }
}

fn split_reg(whole: u64) -> (u32, u32) {
    let hi = (whole >> 32) as u32;
    let lo = (whole & ((1 << 32) - 1)) as u32;
    (hi, lo)
}

fn join_reg(hi: u32, lo: u32) -> u64 {
    (hi as u64) << 32 | (lo as u64)
}
