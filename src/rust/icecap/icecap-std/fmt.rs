use core::fmt;
use alloc::boxed::Box;

use icecap_core::sel4::debug_put_char;
use icecap_core::interfaces::ConDriver;

struct IceCapDebugWriter;

impl fmt::Write for IceCapDebugWriter {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for &c in s.as_bytes() {
            debug_put_char(c)
        }
        Ok(())
    }
}

struct IceCapConWriter {
    driver: ConDriver,
}

impl IceCapConWriter {
    fn new(driver: ConDriver) -> Self {
        Self {
            driver,
        }
    }
}

impl fmt::Write for IceCapConWriter {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        self.driver.tx(s.as_bytes());
        Ok(())
    }
}

fn print_to(global_writer: &mut Option<Box<IceCapConWriter>>, args: fmt::Arguments) {
    match {
        match global_writer {
            None => {
                let mut writer = IceCapDebugWriter {};
                fmt::write(&mut writer, args)
            },
            Some(b) => {
                let writer: &mut IceCapConWriter = b;
                fmt::write(writer, args)
            },
        }
    } {
        Ok(_) => {},
        Err(err) => panic!("write error: {:?}", err),
    }
}

// TODO synchronize with mutex from c runtime?
static mut GLOBAL_WRITER: Option<Box<IceCapConWriter>> = None;

pub fn set_print(driver: ConDriver) {
    // TODO
    unsafe {
        GLOBAL_WRITER = Some(Box::new(IceCapConWriter::new(driver)));
    }
}

pub fn _print(args: fmt::Arguments) {
    unsafe {
        print_to(&mut GLOBAL_WRITER, args)
    }
}

#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => ($crate::_fmt::_print(format_args!($($arg)*)));
}

#[macro_export]
macro_rules! println {
    () => ($crate::_fmt::print!("\n"));
    ($($arg:tt)*) => ({
        $crate::_fmt::_print(format_args_nl!($($arg)*));
    })
}
