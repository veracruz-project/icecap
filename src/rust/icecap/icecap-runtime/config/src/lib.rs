#![no_std]

// TODO split into with-alloc and without-alloc parts
extern crate alloc;

use core::mem;
use core::slice;
use alloc::vec::Vec;

mod c;

pub use c::Config;

fn as_bytes<T: ?Sized>(v: &T) -> &[u8] {
    unsafe {
        slice::from_raw_parts((v as *const T) as *const u8, mem::size_of_val(v))
    }
}

impl Config {
    pub fn serialize(&self) -> Vec<u8> {
        let mut v = as_bytes(&self.common).to_vec();
        v.extend_from_slice(as_bytes(&self.threads.len()));
        for thread in &self.threads {
            v.extend_from_slice(as_bytes(thread));
        }
        v
    }
}
