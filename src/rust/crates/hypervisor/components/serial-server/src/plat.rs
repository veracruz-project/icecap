#[cfg(icecap_plat = "virt")]
mod plat_impl {
    use icecap_drivers::serial::VirtSerialDevice;

    pub fn serial_device(base_addr: usize) -> VirtSerialDevice {
        let dev = VirtSerialDevice::new(base_addr);
        dev.init();
        dev
    }
}

#[cfg(icecap_plat = "rpi4")]
mod plat_impl {
    use icecap_drivers::serial::Rpi4SerialDevice;

    pub fn serial_device(base_addr: usize) -> Rpi4SerialDevice {
        let dev = Rpi4SerialDevice::new(base_addr);
        dev.init();
        dev
    }
}

pub use plat_impl::*;
