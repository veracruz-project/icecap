#![no_std]

mod cspace;

pub mod prelude;

pub use cspace::*;

use serde::{Serialize, Deserialize};

#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
pub struct Thread(Endpoint);

pub type Badge = u64;
pub type Slot = u64;
