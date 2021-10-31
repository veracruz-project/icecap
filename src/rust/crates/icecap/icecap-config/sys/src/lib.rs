#![no_std]

#[cfg(target_os = "icecap")]
mod icecap;
#[cfg(target_os = "icecap")]
pub use icecap::*;

#[cfg(target_os = "linux")]
mod linux;
#[cfg(target_os = "linux")]
pub use linux::*;
