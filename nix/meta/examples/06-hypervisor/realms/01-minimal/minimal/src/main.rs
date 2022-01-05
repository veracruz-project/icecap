#![no_std]
#![no_main]
#![feature(format_args_nl)]

extern crate alloc;

use serde::{Serialize, Deserialize};
use icecap_std::prelude::*;
use icecap_std::config::*;

declare_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    con: UnmanagedRingBufferConfig,
}

fn main(config: Config) -> Fallible<()> {
    let mut con = RingBuffer::realize_resume_unmanaged(&config.con);
    con.write(b"Hello, World!");
    Ok(())
}
