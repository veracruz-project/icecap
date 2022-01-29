#![no_std]

extern crate alloc;

use serde::{Deserialize, Serialize};

use icecap_rpc_types::*;

pub type RealmId = usize;

pub type PhysicalNodeIndex = usize;
pub type VirtualNodeIndex = usize;
pub type Nanoseconds = usize;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum Request {
    Declare {
        realm_id: RealmId,
        spec_size: usize,
    },
    SpecChunk {
        realm_id: usize,
        bulk_data_offset: usize,
        bulk_data_size: usize,
        offset: usize,
    },
    FillChunks {
        realm_id: usize,
        bulk_data_offset: usize,
        bulk_data_size: usize,
    },
    RealizeStart {
        realm_id: RealmId,
    },
    RealizeFinish {
        realm_id: RealmId,
    },
    Destroy {
        realm_id: RealmId,
    },

    // still around for benchmarking
    HackRun {
        realm_id: RealmId,
    },
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct FillChunkHeader {
    pub object_index: usize,
    pub fill_entry_index: usize,
    pub size: usize,
}

#[derive(Clone, Debug)]
pub struct Yield {
    pub physical_node: usize,
    pub realm_id: usize,
    pub virtual_node: usize,
    pub timeout: Option<Nanoseconds>,
}

#[derive(Clone, Debug)]
pub enum ResumeHostCondition {
    Timeout,
    HostEvent,
    RealmYieldedBack(YieldBackCondition),
}

#[derive(Clone, Debug)]
pub enum YieldBackCondition {
    WFE { timeout: Nanoseconds },
    // Message,
}

// #[derive(Clone, Debug)]
// pub enum Message {
// }

impl RPC for Yield {
    fn send(&self, _call: &mut impl Sending) {
        // TODO
        unimplemented!()
    }

    fn recv(call: &mut impl Receiving) -> Self {
        fn get_field(reg: u64, i: i32) -> usize {
            const WIDTH: i32 = 16;
            const MASK: u64 = (1 << WIDTH) - 1;
            ((reg >> (i * WIDTH)) & MASK) as usize
        }
        fn decode_option(reg: u64) -> Option<usize> {
            if reg == 0 {
                None
            } else {
                Some((reg & !(1 << 63)) as usize)
            }
        }
        let swap = call.read_value();
        let physical_node = get_field(swap, 0);
        let realm_id = get_field(swap, 1);
        let virtual_node = get_field(swap, 2);
        let timeout = decode_option(call.read_value());
        Self {
            physical_node,
            realm_id,
            virtual_node,
            timeout,
        }
    }
}

const RESUME_HOST_CONDITION_TAG_TIMEOUT: u64 = 1;
const RESUME_HOST_CONDITION_TAG_HOST_EVENT: u64 = 2;

impl RPC for ResumeHostCondition {
    fn send(&self, call: &mut impl Sending) {
        match self {
            Self::Timeout => {
                call.write_value(RESUME_HOST_CONDITION_TAG_TIMEOUT);
            }
            Self::HostEvent => {
                call.write_value(RESUME_HOST_CONDITION_TAG_HOST_EVENT);
            }
            Self::RealmYieldedBack(_) => {
                todo!();
            }
        }
    }

    fn recv(_call: &mut impl Receiving) -> Self {
        // TODO
        unimplemented!()
    }
}
