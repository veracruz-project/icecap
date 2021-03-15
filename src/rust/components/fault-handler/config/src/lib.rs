#![no_std]

extern crate alloc;

use alloc::collections::btree_map::BTreeMap;
use alloc::string::String;
use serde::{Serialize, Deserialize};
use icecap_config::sel4::prelude::*;

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
