#![no_std]

extern crate alloc;

use alloc::vec::Vec;
use serde::{Serialize, Deserialize};
use icecap_config::{sel4::prelude::*, Thread};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
}
