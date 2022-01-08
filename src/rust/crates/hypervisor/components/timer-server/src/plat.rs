cfg_if::cfg_if! {
    if #[cfg(icecap_plat = "virt")] {
        use icecap_virt_timer_driver::VirtTimerDevice;

        pub fn timer_device(base_addr: usize) -> VirtTimerDevice {
            VirtTimerDevice::new(base_addr)
        }
    } else if #[cfg(icecap_plat = "rpi4")] {
        use icecap_bcm_system_timer_driver::BcmSystemTimerDevice;

        pub fn timer_device(base_addr: usize) -> BcmSystemTimerDevice {
            BcmSystemTimerDevice::new(base_addr)
        }
    }
}
