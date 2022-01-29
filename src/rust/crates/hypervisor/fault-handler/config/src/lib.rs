#![no_std]

extern crate alloc;

use alloc::collections::btree_map::BTreeMap;
use alloc::string::String;

use serde::{Deserialize, Serialize};

use icecap_config::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub ep: Endpoint,
    pub threads: BTreeMap<Badge, Thread>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Thread {
    pub name: String,
    pub tcb: TCB,
}
