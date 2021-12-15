#[cfg(icecap_plat = "virt")]
mod plat_impl {
    use crate::device::virt::Device;

    pub fn serial_device(base_addr: usize) -> Device {
        let dev = Device::new(base_addr);
        dev.init();
        dev
    }
}

#[cfg(icecap_plat = "rpi4")]
mod plat_impl {
    use crate::device::rpi4::Device;

    pub fn serial_device(base_addr: usize) -> Device {
        let dev = Device::new(base_addr);
        dev.init();
        dev
    }
}

pub use plat_impl::*;
