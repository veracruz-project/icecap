#![no_std]
#![feature(alloc_prelude)]

extern crate alloc;

use alloc::prelude::v1::*;
use alloc::vec;
use core::mem;
use core::slice;

use serde::{Deserialize, Serialize};

mod c;

pub use c::{CommonConfig, ThreadConfig};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config<T> {
    pub common: CommonConfig,
    pub threads: Vec<ThreadConfig>,
    pub image_path: String,
    pub arg: T,
}

fn as_bytes<T: ?Sized>(v: &T) -> &[u8] {
    unsafe { slice::from_raw_parts(v as *const T as *const u8, mem::size_of_val(v)) }
}

impl<T> Config<T> {
    fn struct_size(&self) -> usize {
        mem::size_of::<CommonConfig>()
        + mem::size_of::<u64>() // num_threads
        + self.threads.len() * mem::size_of::<ThreadConfig>()
    }

    pub fn traverse<U, V>(self, f: impl FnOnce(T) -> Result<U, V>) -> Result<Config<U>, V> {
        Ok(Config {
            common: self.common,
            threads: self.threads,
            image_path: self.image_path,
            arg: f(self.arg)?,
        })
    }
}

impl<T: AsRef<[u8]>> Config<T> {
    pub fn serialize(mut self) -> Vec<Vec<u8>> {
        assert_eq!(self.common.image_path_offset, 0);
        assert_eq!(self.common.arg.offset, 0);
        assert_eq!(self.common.arg.size, 0);

        let mut blob = vec![];

        self.common.image_path_offset = (self.struct_size() + blob.len()) as u64;
        blob.extend_from_slice(self.image_path.as_bytes());
        blob.push(0);

        self.common.arg.offset = (self.struct_size() + blob.len()) as u64;
        self.common.arg.size = self.arg.as_ref().len() as u64;
        blob.extend_from_slice(self.arg.as_ref());

        let mut struct_ = as_bytes(&self.common).to_vec();
        struct_.extend_from_slice(as_bytes(&(self.threads.len() as u64)));
        for thread in &self.threads {
            struct_.extend_from_slice(as_bytes(thread));
        }

        assert_eq!(struct_.len(), self.struct_size());

        vec![struct_, blob]
    }
}
