#![no_std]

use serde::{Serialize, Deserialize};

mod cspace;

pub use cspace::*;

pub type Badge = u64;
pub type Slot = u64;

#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct Thread(Endpoint);
