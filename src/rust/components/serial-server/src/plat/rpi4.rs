use crate::device::rpi4::Device;

pub const SERIAL_INTERRUPT: i64 = 125;

const BUS_ADDR_OFFSET: usize = 0x7E000000;
const PADDDR_OFFSET: usize = 0xFE000000;
const UART_BUSADDR: usize = 0x7E215000;

pub const SERIAL_PADDR: usize = UART_BUSADDR - BUS_ADDR_OFFSET + PADDDR_OFFSET;

pub fn serial_device(base_addr: usize) -> Device {
    let dev = Device::new(base_addr);
    dev.init();
    dev
}
