#![no_std]

extern crate alloc;

use core::mem;
use alloc::vec::Vec;
use serde::{Serialize, Deserialize};

// #[derive(Clone, Debug)]
// pub struct Call {
//     pub id: u64,
//     pub num_args: usize,
//     pub num_ret: usize,
// }

pub mod calls {
    // use super::Call;

    // pub const DECLARE: Call = Call { id: 1, num_args: 1, num_ret: 1 };
    // pub const REALIZE: Call = Call { id: 2, num_args: 3, num_ret: 0 };
    // pub const PUT: Call = Call { id: 3, num_args: 3, num_ret: 0 };
    // pub const TAKE: Call = Call { id: 4, num_args: 2, num_ret: 0 };
    // pub const DESTROY: Call = Call { id: 5, num_args: 1, num_ret: 0 };

    pub const DECLARE: usize = 1;
    pub const REALIZE: usize = 2;
    pub const PUT: usize = 3;
    pub const TAKE: usize = 4;
    pub const DESTROY: usize = 5;
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
