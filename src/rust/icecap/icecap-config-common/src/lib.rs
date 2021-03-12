#![no_std]

extern crate alloc;

use alloc::vec::Vec;
use serde::{Serialize, Deserialize};
use icecap_sel4::prelude::*;

pub use icecap_sel4 as sel4;
pub use icecap_runtime::{
    self as runtime,
    Thread,
};

// TODO rename these types

pub type DescRingBuffers<T> = Vec<DescRingBuffer<T>>;

pub type DescMappedRingBuffer = DescRingBuffer<usize>;
pub type DescMappedRingBuffers = DescRingBuffers<usize>;
pub type DescUnmappedRingBuffer = DescRingBuffer<Vec<SmallPage>>;
pub type DescUnmappedRingBuffers = DescRingBuffers<Vec<SmallPage>>;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DescRingBuffer<T> {
    pub wait: Notification,
    pub read: DescRingBufferSide<T>,
    pub write: DescRingBufferSide<T>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DescRingBufferSide<T> {
    pub signal: Notification,
    pub size: usize,
    pub ctrl: T,
    pub data: T,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DescTimerClient {
    pub ep_write: Endpoint,
    pub wait: Notification,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DynamicUntyped {
    pub slot: Untyped,
    pub size_bits: usize,
    pub paddr: Option<usize>,
    pub device: bool,
}
