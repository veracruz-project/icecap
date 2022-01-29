#![no_std]

extern crate alloc;

mod parameter;
mod transit;
mod rpc;

pub use transit::{Receiving, Sending};
pub use parameter::{Parameter, ParameterValue};
pub use rpc::RPC;
