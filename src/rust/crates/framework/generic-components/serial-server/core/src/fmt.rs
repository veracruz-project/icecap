use core::fmt;

use icecap_driver_interfaces::SerialDevice;

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
    ($dst:expr, $($arg:tt)*) => (core::fmt::Write::write_fmt(&mut $crate::fmt::Writer($dst), format_args!($($arg)*)).unwrap());
}
