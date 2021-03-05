#![no_std]

extern crate alloc;

use core::mem;
use core::ops::Range;
use alloc::vec::Vec;
use serde::{Serialize, Deserialize};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum Message {
    Start { size: usize },
    Chunk { range: Range<usize> },
    End,
}

pub type Header = usize;
pub type HeaderFormat = u32;

impl Message {

    pub const HEADER_SIZE: usize = mem::size_of::<HeaderFormat>();

    pub fn parse_header(bytes: [u8; Self::HEADER_SIZE]) -> usize {
        HeaderFormat::from_le_bytes(bytes) as usize
    }

    pub fn mk_header(header: Header) -> [u8; Self::HEADER_SIZE] {
        HeaderFormat::to_le_bytes(header as u32)
    }

    pub fn parse(bytes: &[u8]) -> pinecone::Result<Self> {
        pinecone::from_bytes(bytes)
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

    // // TODO #[cfg(not(target_os = "icecap"))] or with std
    // // NOTE f takes an uninitialized slice (e.g. read_exact)
    // pub fn read<E>(mut f: impl FnMut(&mut [u8]) -> Result<(), E>) -> Result<Message, Error<E>> {
    //     let mut header = [0; mem::size_of::<Header>()];
    //     f(&mut header).map_err(Either::Left)?;
    //     let n = Header::from_le_bytes(header) as usize;
    //     let mut msg = Vec::with_capacity(n);
    //     unsafe {
    //         msg.set_len(n);
    //     }
    //     f(&mut msg).map_err(Either::Left)?;
    //     let msg = Self::parse(&msg).map_err(Either::Right)?;
    //     Ok(msg)
    // }

}
