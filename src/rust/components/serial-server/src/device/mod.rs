use core::fmt;

pub mod rpi4;
pub mod virt;

pub trait SerialDevice {
    fn put_char(&self, c: u8);
    fn get_char(&self) -> Option<u8>;
    fn handle_irq(&self);
}

// HACK

pub struct Writer<'a, T>(pub &'a T);

impl<T: SerialDevice> fmt::Write for Writer<'_, T> {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for c in s.as_bytes() {
            self.0.put_char(*c)
        }
        Ok(())
    }
}

#[macro_export]
macro_rules! out {
    ($dst:expr, $($arg:tt)*) => ($crate::device::Writer($dst).write_fmt(format_args!($($arg)*)).unwrap());
}
