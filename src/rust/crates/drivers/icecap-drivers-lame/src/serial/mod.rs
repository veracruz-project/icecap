mod virt;
mod rpi4;

// TODO Fix names
pub use rpi4::Device as Rpi4SerialDevice;
pub use virt::Device as VirtSerialDevice;

pub trait SerialDevice {
    fn put_char(&self, c: u8);
    fn get_char(&self) -> Option<u8>;
    fn handle_irq(&self);
}
