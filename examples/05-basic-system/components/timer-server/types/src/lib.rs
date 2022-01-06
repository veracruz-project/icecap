#![no_std]

extern crate alloc;

use serde::{Serialize, Deserialize};

use icecap_core::prelude::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Request {
}
