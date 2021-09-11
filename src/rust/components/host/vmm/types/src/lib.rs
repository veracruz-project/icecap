#![no_std]

use serde::{Serialize, Deserialize};

pub type SysId = u64;
pub mod sys_id {
    use super::SysId;

    pub const RESOURCE_SERVER_PASSTHRU: SysId = 1338;
    pub const DIRECT: SysId = 1538;
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum DirectRequest {
    BenchmarkUtilisationStart,
    BenchmarkUtilisationFinish,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DirectResponse;
