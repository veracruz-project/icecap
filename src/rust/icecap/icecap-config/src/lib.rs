#![no_std]

extern crate alloc;

use alloc::vec::Vec;
use serde::{Serialize, Deserialize};

pub use icecap_config_sys::*;

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
