#![no_std]

extern crate alloc;

use serde::{Serialize, Deserialize};

pub type RealmId = usize;

pub type PhysicalNodeIndex = usize;
pub type VirtualNodeIndex = usize;
pub type Nanoseconds = usize;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum Request {
    Declare { realm_id: RealmId, spec_size: usize },
    SpecChunk { realm_id: usize, bulk_data_offset: usize, bulk_data_size: usize, offset: usize },
    FillChunk { realm_id: usize, bulk_data_offset: usize, bulk_data_size: usize, object_index: usize, fill_entry_index: usize, offset: usize },
    Realize { realm_id: RealmId },
    Destroy { realm_id: RealmId },

    // still around for benchmarking
    HackRun { realm_id: RealmId },
}


#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum YieldBackCondition {
    WFE { timeout: Nanoseconds },
    // Message,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum ResumeHostCondition {
    Timeout,
    HostEvent,
    RealmYieldedBack(YieldBackCondition),
}

// #[derive(Clone, Debug, Serialize, Deserialize)]
// pub enum Message {
// }
