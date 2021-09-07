#![no_std]
#![feature(alloc_prelude)]
#![allow(unused_imports)]

extern crate alloc;

use alloc::prelude::v1::*;
use serde::{Serialize, Deserialize};
use icecap_config::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub self_tcb: TCB,
    pub ep: Endpoint,
}
