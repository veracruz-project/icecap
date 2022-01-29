use alloc::boxed::Box;
use core::fmt;

use icecap_core::failure::Fallible;
use icecap_core::ring_buffer::BufferedRingBuffer;
use icecap_core::sel4::debug_put_char;
use icecap_core::sync::{unsafe_static_mutex, GenericMutex};

unsafe_static_mutex!(Lock, icecap_runtime_print_lock);

static GLOBAL_PRINT: GenericMutex<Lock, Option<Box<dyn Print + Send>>> =
    GenericMutex::new(Lock, None);

pub trait Print {
    // HACK workaround for https://doc.rust-lang.org/reference/items/traits.html#object-safety (see 'PrintWrapper')
    fn write_str(&mut self, s: &str) -> fmt::Result;

    fn flush(&mut self) -> Fallible<()> {
        Ok(())
    }
}

pub fn set_print(print: Box<dyn Print + Send>) {
    let mut global_print = GLOBAL_PRINT.lock();
    *global_print = Some(print);
}

pub fn flush_print() -> Fallible<()> {
    let mut global_print = GLOBAL_PRINT.lock();
    if let Some(print) = &mut *global_print {
        print.flush()?;
    }
    Ok(())
}

// HACK workaround for https://doc.rust-lang.org/reference/items/traits.html#object-safety
struct PrintWrapper<'a>(&'a mut Box<dyn Print + Send>);

impl<'a> fmt::Write for PrintWrapper<'a> {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        self.0.write_str(s)
    }
}

#[doc(hidden)]
pub fn _print(args: fmt::Arguments) {
    let mut global_print = GLOBAL_PRINT.lock();
    if let Some(print) = &mut *global_print {
        fmt::write(&mut PrintWrapper(print), args).unwrap();
    }
}

#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => ($crate::fmt::_print(format_args!($($arg)*)));
}

#[macro_export]
macro_rules! println {
    () => ($crate::print!("\n"));
    ($($arg:tt)*) => ({
        // NOTE
        // If feature(format_args_nl) is ever stabilized, replace with:
        // $crate::fmt::_print(format_args_nl!($($arg)*));
        $crate::print!($($arg)*);
        $crate::print!("\n");
    })
}

// // //

struct DebugPrint;

impl Print for DebugPrint {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for &c in s.as_bytes() {
            debug_put_char(c)
        }
        Ok(())
    }
}

struct BufferedRingBufferPrint {
    ring_buffer: BufferedRingBuffer,
}

impl BufferedRingBufferPrint {
    fn new(ring_buffer: BufferedRingBuffer) -> Self {
        Self { ring_buffer }
    }
}

impl Print for BufferedRingBufferPrint {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        self.ring_buffer.tx(s.as_bytes());
        Ok(())
    }

    fn flush(&mut self) -> Fallible<()> {
        self.ring_buffer.flush_tx();
        Ok(())
    }
}
