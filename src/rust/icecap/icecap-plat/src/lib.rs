#![no_std]

use numeric_literal_env_hack::env_usize;

pub const NUM_CORES: usize = env_usize!("NUM_CORES");
