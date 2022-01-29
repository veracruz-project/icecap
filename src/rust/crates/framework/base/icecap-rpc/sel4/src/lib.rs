#![no_std]

extern crate alloc;

use alloc::vec::Vec;
use core::marker::PhantomData;

use icecap_sel4::prelude::*;

pub use icecap_rpc::*;

struct ReceivingImpl {
    length: usize,
    cursor: usize,
}

impl ReceivingImpl {
    fn new(length: usize) -> Self {
        Self { length, cursor: 0 }
    }

    fn complete<T: RPC>(info: &MessageInfo) -> T {
        let mut receiving = Self::new(info.length() as usize);
        T::recv(&mut receiving)
    }
}

impl Receiving for ReceivingImpl {
    fn read_value(&mut self) -> ParameterValue {
        assert_ne!(self.cursor, self.length);
        let value = MessageRegister::new(self.cursor as i32).get();
        self.cursor += 1;
        value
    }

    fn remaining(&self) -> usize {
        self.length - self.cursor
    }
}

struct SendingImpl {
    cursor: usize,
}

impl SendingImpl {
    fn new() -> Self {
        Self { cursor: 0 }
    }

    fn complete(message: &impl RPC) -> MessageInfo {
        let mut sending = SendingImpl::new();
        message.send(&mut sending);
        let length = sending.cursor;
        MessageInfo::new(0, 0, 0, length as u64)
    }
}

impl Sending for SendingImpl {
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

    pub fn send(&self, input: &Input) {
        self.endpoint.send(SendingImpl::complete(input))
    }

    pub fn call<Output: RPC>(&self, input: &Input) -> Output {
        ReceivingImpl::complete(&self.endpoint.call(SendingImpl::complete(input)))
    }
}

pub mod rpc_server {
    use super::*;

    pub fn prepare<Output: RPC>(output: &Output) -> MessageInfo {
        SendingImpl::complete(output)
    }

    pub fn recv<Input: RPC>(info: &MessageInfo) -> Input {
        ReceivingImpl::complete(info)
    }

    pub fn send<Output: RPC>(endpoint: Endpoint, output: &Output) {
        endpoint.send(SendingImpl::complete(output))
    }

    pub fn reply<Output: RPC>(output: &Output) {
        sel4::reply(SendingImpl::complete(output))
    }
}

pub mod proxy {
    use super::*;

    pub fn down(info: &MessageInfo) -> Vec<ParameterValue> {
        let mut parameters = Vec::new();
        let length = info.length() as usize;
        let mut receiving = ReceivingImpl::new(length);
        for _ in 0..length {
            parameters.push(receiving.read());
        }
        parameters
    }

    pub fn up(parameters: &[ParameterValue]) -> MessageInfo {
        let mut sending = SendingImpl::new();
        for parameter in parameters {
            sending.write(*parameter);
        }
        MessageInfo::new(0, 0, 0, parameters.len() as u64)
    }
}
