#![no_std]

pub const KHZ: u64 = 1000;
pub const MHZ: u64 = 1000 * KHZ;
pub const GHZ: u64 = 1000 * MHZ;

pub trait TimerDevice {
    fn get_freq(&self) -> u32;
    fn set_enable(&self, enabled: bool);
    fn get_count(&self) -> u64;
    fn set_compare(&self, compare: u64) -> bool;
    fn clear_interrupt(&self);
}

pub trait SerialDevice {
    fn put_char(&self, c: u8);
    fn get_char(&self) -> Option<u8>;
    fn handle_interrupt(&self);
}
