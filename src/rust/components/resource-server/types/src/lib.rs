#![no_std]

extern crate alloc;

use core::mem;
use alloc::vec::Vec;
use serde::{Serialize, Deserialize};

pub mod calls {
    pub const DECLARE: usize = 1;
    pub const REALIZE: usize = 2;
    pub const YIELD_TO: usize = 3;
    pub const DESTROY: usize = 4;
}

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
