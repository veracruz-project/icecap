#![no_std]

extern crate alloc;

use core::marker::PhantomData;
use alloc::vec::Vec;
use icecap_sel4::prelude::*;

pub use icecap_rpc::*;

struct ReadCallImpl {
    length: usize,
    cursor: usize,
}

impl ReadCallImpl {

    fn new(length: usize) -> Self {
        Self {
            length,
            cursor: 0,
        }
    }

    fn complete<T: RPC>(info: &MessageInfo) -> T {
        let mut call = Self::new(info.length() as usize);
        T::recv(&mut call)
    }
}

impl ReadCall for ReadCallImpl {

    fn read_value(&mut self) -> ParameterValue {
        assert_ne!(self.cursor, self.length);
        let value = MessageRegister::new(self.cursor as i32).get();
        self.cursor += 1;
        value
    }
}

struct WriteCallImpl {
    cursor: usize,
}

impl WriteCallImpl {

    fn new() -> Self {
        Self {
            cursor: 0,
        }
    }

    fn complete(message: &impl RPC) -> MessageInfo {
        let mut call = WriteCallImpl::new();
        message.send(&mut call);
        let length = call.cursor;
        MessageInfo::new(0, 0, 0, length as u64)
    }
}

impl WriteCall for WriteCallImpl {

    fn write_value(&mut self, value: ParameterValue) {
        MessageRegister::new(self.cursor as i32).set(value);
        self.cursor += 1;
    }
}

#[derive(Clone)]
pub struct RPCClient<Input> {
    endpoint: Endpoint,
    phantom: PhantomData<Input>,
}

impl<Input: RPC> RPCClient<Input> {

    pub fn new(endpoint: Endpoint) -> Self {
        Self {
            endpoint,
            phantom: PhantomData,
        }
    }

    pub fn call<Output: RPC>(&self, input: &Input) -> Output {
        ReadCallImpl::complete(&self.endpoint.call(WriteCallImpl::complete(input)))
    }
}

pub mod rpc_server {
    use super::*;

    pub fn prepare<Output: RPC>(output: &Output) -> MessageInfo {
        WriteCallImpl::complete(output)
    }

    pub fn recv<Input: RPC>(info: &MessageInfo) -> Input {
        ReadCallImpl::complete(info)
    }

    pub fn send<Output: RPC>(endpoint: Endpoint, output: &Output) {
        endpoint.send(WriteCallImpl::complete(output))
    }

    pub fn reply<Output: RPC>(output: &Output) {
        sel4::reply(WriteCallImpl::complete(output))
    }
}

pub mod proxy {
    use super::*;

    pub fn down(info: &MessageInfo) -> Vec<ParameterValue> {
        let mut parameters = Vec::new();
        let length = info.length() as usize;
        let mut call = ReadCallImpl::new(length);
        for _ in 0..length {
            parameters.push(call.read());
        }
        parameters
    }

    pub fn up(parameters: &[ParameterValue]) -> MessageInfo {
        let mut call = WriteCallImpl::new();
        for parameter in parameters {
            call.write(*parameter);
        }
        MessageInfo::new(0, 0, 0, parameters.len() as u64)
    }
}
