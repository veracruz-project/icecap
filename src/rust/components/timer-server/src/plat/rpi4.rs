use crate::device::BcmSystemTimerDevice;

pub const TIMER_PADDR: u64 = 0xFE003000;
pub const TIMER_INTERRUPT: i64 = 97;

pub fn timer_device(base_addr: usize) -> BcmSystemTimerDevice {
    BcmSystemTimerDevice::new(base_addr)
}
