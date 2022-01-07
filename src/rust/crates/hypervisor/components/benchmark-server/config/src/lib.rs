#![no_std]

extern crate alloc;

use icecap_config::*;

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub self_tcb: TCB,
    pub ep: Endpoint,
}
