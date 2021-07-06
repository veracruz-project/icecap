#![no_std]

extern crate alloc;

use core::mem;
use alloc::vec::Vec;
use serde::{Serialize, Deserialize};

pub type RealmId = usize;
pub type PhysicalNodeIndex = usize;
pub type VirtualNodeIndex = usize;

pub type Nanoseconds = usize;

pub enum YieldBackCondition {
    WFE { timeout: Nanoseconds },
    // Message,
}

pub enum ResumeHostCondition {
    Timeout,
    HostEvent,
    RealmYieldedBack(YieldBackCondition),
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum Request {
    Declare { realm_id: RealmId, spec_size: usize },
    SpecChunk { realm_id: usize, bulk_data_offset: usize, bulk_data_size: usize, offset: usize },
    FillChunk { realm_id: usize, bulk_data_offset: usize, bulk_data_size: usize, object_index: usize, fill_entry_index: usize, offset: usize },
    Realize { realm_id: RealmId },
    Destroy { realm_id: RealmId },
    YieldTo { physical_node: PhysicalNodeIndex, realm_id: RealmId, virtual_node: VirtualNodeIndex, timeout: Nanoseconds },
    HackRun { realm_id: RealmId },
}

///

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum Message {

}
