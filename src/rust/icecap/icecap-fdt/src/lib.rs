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

// use error::{
//     warn_malformed, bail, ensure,
// };
pub use error::{
    Error, Result,
};

pub use types::{DeviceTree, ReserveEntry, Node, Value};
