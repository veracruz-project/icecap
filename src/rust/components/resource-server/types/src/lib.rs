#![no_std]

extern crate alloc;

use core::mem;
use alloc::vec::Vec;
use serde::{Serialize, Deserialize};

use icecap_rpc::*;

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

pub enum Request {
    Declare { realm_id: RealmId, spec_size: usize },
    Realize { realm_id: RealmId },
    Destroy { realm_id: RealmId },
    YieldTo { physical_node: PhysicalNodeIndex, realm_id: RealmId, virtual_node: VirtualNodeIndex, timeout: Nanoseconds },
}

mod calls {
    use super::*;

    pub const DECLARE: ParameterValue = 1;
    pub const REALIZE: ParameterValue = 2;
    pub const DESTROY: ParameterValue = 3;
    pub const YIELD_TO: ParameterValue = 4;
}

impl RPC for Request {

    fn send(&self, call: &mut impl WriteCall) {
        match *self {
            Request::Declare { realm_id, spec_size } => {
                call.write(calls::DECLARE);
                call.write(realm_id);
                call.write(spec_size);
            }
            Request::Realize { realm_id } => {
                call.write(calls::REALIZE);
                call.write(realm_id);
            }
            Request::Destroy { realm_id } => {
                call.write(calls::DESTROY);
                call.write(realm_id);
            }
            Request::YieldTo { physical_node, realm_id, virtual_node, timeout } => {
                call.write(calls::YIELD_TO);
                call.write(physical_node);
                call.write(realm_id);
                call.write(virtual_node);
                call.write(timeout);
            }
        }
    }

    fn recv(call: &mut impl ReadCall) -> Self {
        match call.read() {
            calls::DECLARE => Request::Declare { realm_id: call.read(), spec_size: call.read() },
            calls::REALIZE => Request::Realize { realm_id: call.read() },
            calls::DESTROY => Request::Destroy { realm_id: call.read() },
            calls::YIELD_TO => Request::YieldTo { physical_node: call.read(), realm_id: call.read(), virtual_node: call.read(), timeout: call.read() },
            _ => panic!(),
        }
    }
}

pub mod response {
    use super::*;

    impl RPC for ResumeHostCondition {

        fn send(&self, call: &mut impl WriteCall) {
            todo!()
        }
    
        fn recv(call: &mut impl ReadCall) -> Self {
            todo!()
        }
    }
}

///

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum Message {
    SpecChunk { realm_id: usize, offset: usize },
    FillChunk { realm_id: usize, object_index: usize, fill_entry_index: usize, offset: usize },
}

pub type Header = usize;
pub type HeaderFormat = u32;

impl Message {

    pub const HEADER_SIZE: usize = mem::size_of::<HeaderFormat>();

    pub fn mk_header(header: Header) -> [u8; Self::HEADER_SIZE] {
        HeaderFormat::to_le_bytes(header as u32)
    }

    pub fn mk(&self) -> Vec<u8> {
        pinecone::to_vec(self).unwrap()
    }

    pub fn mk_with_header(&self) -> ([u8; Self::HEADER_SIZE], Vec<u8>) {
        let msg = self.mk();
        let hdr = msg.len();
        let hdr = Self::mk_header(hdr);
        (hdr, msg)
    }

    pub fn mk_content_header(content: &[u8]) -> [u8; Self::HEADER_SIZE] {
        HeaderFormat::to_le_bytes(content.len() as u32)
    }

    pub fn parse(bytes: &[u8]) -> pinecone::Result<Self> {
        pinecone::from_bytes(bytes)
    }
}
