use core::fmt;

use crate::debug_put_char;

struct Debug;

impl fmt::Write for Debug {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for &c in s.as_bytes() {
            debug_put_char(c)
        }
        Ok(())
    }
}

pub fn _debug_print(args: fmt::Arguments) {
    fmt::write(&mut Debug, args).unwrap_or_else(|err| {
        panic!("write error: {:?}", err) // TODO panicking could result in loop
    })
}

#[macro_export]
macro_rules! debug_print {
    ($($arg:tt)*) => ($crate::_fmt::_debug_print(format_args!($($arg)*)));
}

#[macro_export]
macro_rules! debug_println {
    () => ($crate::debug_print!("\n"));
    ($($arg:tt)*) => ({
        // NOTE
        // If feature(format_args_nl) is ever stabilized, replace with:
        // $crate::_fmt::_debug_print(format_args_nl!($($arg)*));
        $crate::debug_print!($($arg)*);
        $crate::debug_print!("\n");
    })
}
