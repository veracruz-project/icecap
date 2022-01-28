#![no_std]

extern crate alloc;

use icecap_failure::Fallible;
use icecap_sel4::debug_println;
use icecap_start::config;

pub fn run_generic_main<T: config::Config>(
    f: impl Fn(T) -> Fallible<()>,
    config: *const u8,
    config_size: usize,
) {
    let s: &'static [u8] = unsafe { core::slice::from_raw_parts(config, config_size) };
    let config = match serde_json::from_slice(s) {
        Ok(config) => config,
        Err(err) => {
            debug_println!("failed to deserialize generic config: {}", err);
            return;
        }
    };
    if let Err(err) = f(config) {
        debug_println!("err: {}", err)
    }
}

#[macro_export]
macro_rules! declare_generic_main {
    ($main:path) => {
        #[no_mangle]
        pub extern "C" fn icecap_main(config: *const u8, config_size: usize) {
            $crate::run_generic_main($main, config, config_size);
        }
    };
}
