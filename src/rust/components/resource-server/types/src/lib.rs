#![no_std]

extern crate alloc;

use serde::{Serialize, Deserialize};
use icecap_rpc::*;

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

    fn send(&self, _call: &mut impl WriteCall) {
        // TODO
        unimplemented!()
    }

    fn recv(call: &mut impl ReadCall) -> Self {
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
            physical_node, realm_id, virtual_node, timeout,
        }
    }
}

impl RPC for ResumeHostCondition {

    fn send(&self, _call: &mut impl WriteCall) {
        // TODO
    }

    fn recv(_call: &mut impl ReadCall) -> Self {
        // TODO
        unimplemented!()
    }
}
