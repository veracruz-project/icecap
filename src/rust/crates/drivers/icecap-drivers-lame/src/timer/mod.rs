mod virt;
mod rpi4;

// TODO Fix names
pub use rpi4::BcmSystemTimerDevice;
pub use virt::QemuTimerDevice;

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
