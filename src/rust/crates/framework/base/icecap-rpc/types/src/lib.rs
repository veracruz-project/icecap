#![no_std]

extern crate alloc;

mod parameter;
mod transit;
mod rpc;

pub use parameter::{Parameter, ParameterValue};
pub use rpc::RPC;
pub use transit::{Receiving, Sending};
