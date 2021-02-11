#![no_std]
#![allow(dead_code)]

#[macro_use]
extern crate alloc;

mod device;
pub use device::IceCapDevice;
