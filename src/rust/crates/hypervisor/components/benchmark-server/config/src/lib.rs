#![no_std]

extern crate alloc;

use serde::{Serialize, Deserialize};
use icecap_config::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub self_tcb: TCB,
    pub ep: Endpoint,
}
