use crate::device::virt::Device;

pub const SERIAL_INTERRUPT: i64 = 33;
pub const SERIAL_PADDR: usize = 0x9000000;

pub fn serial_device(base_addr: usize) -> Device {
    let dev = Device::new(base_addr);
    dev.init();
    dev
}
