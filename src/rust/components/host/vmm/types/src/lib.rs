#![no_std]

extern crate alloc;

use core::mem;
use alloc::vec::Vec;
use serde::{Serialize, Deserialize};

pub type SysId = u64;
pub mod sys_id {
    use super::SysId;

    pub const RESOURCE_SERVER_PASSTHRU: SysId = 1338;
    pub const DIRECT: SysId = 1538;
    pub const YIELD_TO: SysId = 1339;
}


#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum DirectRequest {
    Start,
    Finish,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DirectResponse;
