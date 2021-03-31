use core::fmt;
use alloc::boxed::Box;

use icecap_core::sel4::debug_put_char;
use icecap_core::ring_buffer::BufferedRingBuffer;
use icecap_core::sync::{GenericMutex, unsafe_static_mutex};

unsafe_static_mutex!(Lock, icecap_runtime_heap_lock);

static GLOBAL_WRITER: GenericMutex<Lock, Option<Box<IceCapConWriter>>> = GenericMutex::new(Lock, None);

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
    ring_buffer: BufferedRingBuffer,
}

impl IceCapConWriter {
    fn new(ring_buffer: BufferedRingBuffer) -> Self {
        Self {
            ring_buffer,
        }
    }
}

impl fmt::Write for IceCapConWriter {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        self.ring_buffer.tx(s.as_bytes());
        Ok(())
    }
}

pub fn set_print(ring_buffer: BufferedRingBuffer) {
    let mut global_writer = GLOBAL_WRITER.lock();
    *global_writer = Some(Box::new(IceCapConWriter::new(ring_buffer)));
}

pub fn flush_print() {
    let mut global_writer = GLOBAL_WRITER.lock();
    if let Some(writer) = &mut *global_writer {
        writer.ring_buffer.flush_tx();
    }
}

fn print_to(global_writer: &mut Option<Box<IceCapConWriter>>, args: fmt::Arguments) {
    match global_writer {
        None => {
            let mut writer = IceCapDebugWriter {};
            fmt::write(&mut writer, args)
        }
        Some(b) => {
            let writer: &mut IceCapConWriter = b;
            fmt::write(writer, args)
        }
    }.unwrap_or_else(|err| panic!("{:?}", err))
}

pub fn _print(args: fmt::Arguments) {
    let mut global_writer = GLOBAL_WRITER.lock();
    print_to(&mut global_writer, args)
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
