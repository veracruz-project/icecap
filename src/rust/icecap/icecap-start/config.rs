use alloc::vec::Vec;
use serde::{Serialize, Deserialize};

pub use pinecone::Error as Error;
pub use pinecone::Result as Result;

pub trait Config: Serialize + for<'a> Deserialize<'a> {}

impl<T: Serialize + for<'a> Deserialize<'a>> Config for T {}

pub fn serialize(config: impl Config) -> Result<Vec<u8>> {
    pinecone::to_vec(&config)
}

pub fn deserialize<T: Config>(s: &[u8]) -> Result<T> {
    pinecone::from_bytes(s)
}
