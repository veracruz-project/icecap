cfg_if::cfg_if! {
    if #[cfg(icecap_plat = "virt")] {
        use icecap_pl011_driver::Pl011Device;

        pub fn plat_init_device(base_addr: usize) -> Pl011Device {
            let dev = Pl011Device::new(base_addr);
            dev.init();
            dev
        }
    } else if #[cfg(icecap_plat = "rpi4")] {
        use icecap_bcm2835_aux_uart_driver::Bcm2835AuxUartDevice;

        pub fn plat_init_device(base_addr: usize) -> Bcm2835AuxUartDevice {
            let dev = Bcm2835AuxUartDevice::new(base_addr);
            dev.init();
            dev
        }
    }
}
