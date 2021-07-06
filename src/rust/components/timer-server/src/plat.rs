#[cfg(icecap_plat = "virt")]
mod plat_impl {
    pub use crate::device::QemuTimerDevice as PlatformTimerDevice;

    pub fn timer_device(base_addr: usize) -> PlatformTimerDevice {
        PlatformTimerDevice::new(base_addr)
    }
}

#[cfg(icecap_plat = "rpi4")]
mod plat_impl {
    pub use crate::device::BcmSystemTimerDevice as PlatformTimerDevice;
    
    pub fn timer_device(base_addr: usize) -> PlatformTimerDevice {
        PlatformTimerDevice::new(base_addr)
    }
}

pub use plat_impl::*;
