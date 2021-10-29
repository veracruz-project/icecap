#![no_std]

pub const NUM_CORES: usize = icecap_sel4::sys::CONFIG_MAX_NUM_NODES as usize;
