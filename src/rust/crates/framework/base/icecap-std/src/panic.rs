use core::panic::PanicInfo;

use icecap_core::{backtrace::Backtrace, runtime};

use crate::{print, println};

#[lang = "eh_personality"]
extern "C" fn eh_personality() {}

#[panic_handler]
extern "C" fn panic_handler(info: &PanicInfo) -> ! {
    print!("panicked");
    if let Some(args) = info.message() {
        print!(" with '{}'", args);
    }
    if let Some(loc) = info.location() {
        print!(" at {} {},{}", loc.file(), loc.line(), loc.column());
    }
    print!("\n");

    println!("stack backtrace:");
    println!("    {}", Backtrace::new().raw.serialize());
    println!("");

    loop {
        runtime::stop_component()
    }
}
