#![no_std]

extern crate alloc;

use alloc::vec::Vec;
use alloc::string::String;
use serde::{Serialize, Deserialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RawBacktrace {
    pub path: String,
    pub skip: usize,
    pub stack_frames: Vec<RawStackFrame>,
    pub error: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RawStackFrame {
    pub initial_address: u64,
    pub callsite_address: u64,
}

impl RawBacktrace {

    pub fn serialize(&self) -> String {
        hex::encode(postcard::to_allocvec(self).unwrap())
    }

    pub fn deserialize(s: &str) -> Self {
        postcard::from_bytes(&hex::decode(s).unwrap()).unwrap()
    }

}
