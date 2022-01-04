// HACK

use core::fmt;

use icecap_drivers::serial::SerialDevice;

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
    ($dst:expr, $($arg:tt)*) => ($crate::writer::Writer($dst).write_fmt(format_args!($($arg)*)).unwrap());
}
