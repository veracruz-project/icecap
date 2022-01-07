#![no_std]

extern crate alloc;

mod parameter;
mod call;
mod rpc;

pub use call::{ReadCall, WriteCall};
pub use parameter::{Parameter, ParameterValue};
pub use rpc::RPC;
