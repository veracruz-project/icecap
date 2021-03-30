#![no_std]

extern crate alloc;

mod parameter;
mod call;
mod rpc;

pub use parameter::{Parameter, ParameterValue};
pub use call::{ReadCall, WriteCall};
pub use rpc::RPC;
