#![no_std]

extern crate alloc;

use serde::{Deserialize, Serialize};

pub const NS_IN_S: Nanoseconds = 1_000_000_000;

pub type Nanoseconds = u64;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Request {
    SetTimeout(Nanoseconds),
    GetTime,
}
