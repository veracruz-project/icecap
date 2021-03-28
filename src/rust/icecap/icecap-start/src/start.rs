use icecap_failure::Fallible;
use icecap_sel4::debug_println;

use crate::config;

pub fn run_main<T: config::Config>(f: impl Fn(T) -> Fallible<()>, config: *const u8, config_size: usize) {
    let s: &'static [u8] = unsafe {
        core::slice::from_raw_parts(config, config_size)
    };
    let config = match config::deserialize(s) {
        Ok(config) => config,
        Err(err) => {
            debug_println!("failed to deserialize config: {}", err);
            return
        }
    };
    if let Err(err) = f(config) {
        debug_println!("err: {}", err)
    }
}

#[macro_export]
macro_rules! declare_main {
    ($main:path) => {
        #[no_mangle]
        pub extern "C" fn icecap_main(config: *const u8, config_size: usize) {
            $crate::start::run_main($main, config, config_size);
        }
    }
}

pub fn run_raw_main(f: impl Fn(&[u8]) -> Fallible<()>, config: *const u8, config_size: usize) {
    let s: &'static [u8] = unsafe {
        core::slice::from_raw_parts(config, config_size)
    };
    if let Err(err) = f(s) {
        debug_println!("err: {}", err)
    }
}

#[macro_export]
macro_rules! declare_raw_main {
    ($main:path) => {
        #[no_mangle]
        pub extern "C" fn icecap_main(config: *const u8, config_size: usize) {
            $crate::start::run_raw_main($main, config, config_size);
        }
    }
}
