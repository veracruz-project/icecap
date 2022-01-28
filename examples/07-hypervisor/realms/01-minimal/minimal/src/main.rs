#![no_std]
#![no_main]

extern crate alloc;

use serde::{Deserialize, Serialize};

use icecap_start_generic::declare_generic_main;
use icecap_std::config::*;
use icecap_std::prelude::*;
use icecap_std::ring_buffer::*;

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    con: UnmanagedRingBufferConfig,
}

fn main(config: Config) -> Fallible<()> {
    let mut con = RingBuffer::realize_resume_unmanaged(&config.con);
    con.write(b"Hello, World!");
    con.notify_write();
    Ok(())
}
