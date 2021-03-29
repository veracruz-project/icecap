#![no_std]

pub use icecap_rpc::*;
pub use icecap_sel4::prelude::*;
pub use core::marker::PhantomData;

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

    fn read(&mut self) -> ParameterValue {
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

    fn write(&mut self, value: ParameterValue) {
        MessageRegister::new(self.cursor as i32).set(value);
        self.cursor += 1;
    }
}

#[derive(Clone)] // HACK
pub struct RPCEndpoint<Input> {
    endpoint: Endpoint,
    phantom: PhantomData<Input>,
}

impl<Input: RPC> RPCEndpoint<Input> {

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
