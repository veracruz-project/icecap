use std::marker::PhantomData;
use std::io::{self, Write};
use serde::{Serialize, Deserialize};

pub fn main<T: Serialize + for<'a> Deserialize<'a>>(_: PhantomData<T>) -> Result<(), io::Error> {
    let config: T = serde_json::from_reader(io::stdin())?;
    io::stdout().write_all(&postcard::to_allocvec(&config).unwrap())?;
    Ok(())
}
