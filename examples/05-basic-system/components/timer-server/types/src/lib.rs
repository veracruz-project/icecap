#![no_std]

extern crate alloc;

use serde::{Serialize, Deserialize};

use icecap_core::prelude::*;

pub type Nanoseconds = u64;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Request {
    SetTimeout(Nanoseconds),
    GetTime,
}
