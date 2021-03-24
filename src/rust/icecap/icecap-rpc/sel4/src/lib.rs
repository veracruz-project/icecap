#![no_std]

pub use icecap_rpc::*;
pub use icecap_sel4::prelude::*;
pub use core::marker::PhantomData;

struct CallImpl {
    info: Info,
}

impl Call for CallImpl {

     fn new(info: Info) -> Self {
        Self {
            info,
        }
    }

     fn info(&self) -> &Info {
        &self.info
    }

     fn get(&self, ix: ParameterIndex) -> ParameterValue {
        MessageRegister::new(ix as i32).get()
    }

     fn set(&mut self, ix: ParameterIndex, value: ParameterValue) {
        MessageRegister::new(ix as i32).set(value)
    }
}

fn to_message_info(info: &Info) -> MessageInfo {
    MessageInfo::new(info.label, 0, 0, info.length as u64)
}

fn from_message_info(info: &MessageInfo) -> Info {
    Info {
        label: info.label(),
        length: info.length() as usize,
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
        let info = self.endpoint.call(to_message_info(input.send::<CallImpl>().info()));
        Output::recv(CallImpl::new(from_message_info(&info)))
    }

    pub fn recv(&self, info: &MessageInfo) -> Input {
        Input::recv(CallImpl::new(from_message_info(info)))
    }

}

pub mod rpc_server {
    use super::*;

    pub fn prepare<Output: RPC>(output: &Output) -> MessageInfo {
        to_message_info(output.send::<CallImpl>().info())
    }

    pub fn recv<Input: RPC>(info: &MessageInfo) -> Input {
        Input::recv(CallImpl::new(from_message_info(info)))
    }

    pub fn send<Output: RPC>(endpoint: Endpoint, output: &Output) {
        endpoint.send(to_message_info(output.send::<CallImpl>().info()))
    }

    pub fn reply<Output: RPC>(output: &Output) {
        sel4::reply(to_message_info(output.send::<CallImpl>().info()))
    }
}
