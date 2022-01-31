#![no_std]

extern crate alloc;

use alloc::string::String;
use alloc::vec::Vec;

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RawBacktrace {
    pub path: Option<String>,
    pub stack_frames: Vec<RawStackFrame>,
    pub error: Option<Error>
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Error {}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RawStackFrame {
    // TODO add more detail
    pub ip: usize,
}

impl RawBacktrace {
    pub fn serialize(&self) -> String {
        hex::encode(postcard::to_allocvec(self).unwrap())
    }

    pub fn deserialize(s: &str) -> Self {
        postcard::from_bytes(&hex::decode(s).unwrap()).unwrap()
    }
}
