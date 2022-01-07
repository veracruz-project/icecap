use alloc::vec::Vec;

use serde::{Deserialize, Serialize};

pub use postcard::Error;
pub use postcard::Result;

pub trait Config: Serialize + for<'a> Deserialize<'a> {}

impl<T: Serialize + for<'a> Deserialize<'a>> Config for T {}

pub fn serialize(config: impl Config) -> Result<Vec<u8>> {
    postcard::to_allocvec(&config)
}

pub fn deserialize<T: Config>(s: &[u8]) -> Result<T> {
    postcard::from_bytes(s)
}
