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

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum Request {
    Declare { realm_id: RealmId, spec_size: usize },
    Realize { realm_id: RealmId },
    Destroy { realm_id: RealmId },
    YieldTo { physical_node: PhysicalNodeIndex, realm_id: RealmId, virtual_node: VirtualNodeIndex, timeout: Nanoseconds },

    HackRun { realm_id: RealmId },
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
