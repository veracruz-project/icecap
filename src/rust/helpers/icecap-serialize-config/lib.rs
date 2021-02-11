use std::marker::PhantomData;
use std::io::{self, Write};
use serde::{Serialize, Deserialize};
use pinecone;

pub fn main<T: Serialize + for<'a> Deserialize<'a>>(_: PhantomData<T>) -> Result<(), io::Error> {
    let config: T = serde_json::from_reader(io::stdin())?;
    io::stdout().write_all(&pinecone::to_vec(&config).unwrap())?;
    Ok(())
}
