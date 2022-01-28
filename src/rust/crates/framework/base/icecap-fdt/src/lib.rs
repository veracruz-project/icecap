#![no_std]
#![feature(alloc_prelude)]

#[macro_use]
extern crate alloc;

mod error;
mod types;
mod read;
mod write;
mod debug;
mod utils;

pub mod bindings;

pub use error::{Error, Result};

pub use types::{DeviceTree, Node, ReserveEntry, Value};
