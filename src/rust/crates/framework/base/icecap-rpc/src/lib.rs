#![no_std]

extern crate alloc;

use core::marker::PhantomData;

use icecap_sel4::prelude::*;

pub use icecap_rpc_types::{self as types, *};

struct ReceivingImpl<'a> {
    length: usize,
    cursor: usize,
    ipcbuf: &'a IPCBuffer,
}

impl<'a> ReceivingImpl<'a> {
    fn new(ipcbuf: &'a IPCBuffer, length: usize) -> Self {
        Self {
            ipcbuf,
            length,
            cursor: 0,
        }
    }

    fn complete<T: RPC>(ipcbuf: &IPCBuffer, info: MessageInfo) -> T {
        let mut receiving = ReceivingImpl::new(ipcbuf, info.length() as usize);
        T::recv(&mut receiving)
    }
}

impl<'a> Receiving for ReceivingImpl<'a> {
    fn read_value(&mut self) -> ParameterValue {
        assert_ne!(self.cursor, self.length);
        let value = self.ipcbuf.msg_regs()[self.cursor];
        self.cursor += 1;
        value
    }

    fn remaining(&self) -> usize {
        self.length - self.cursor
    }
}

struct SendingImpl<'a> {
    cursor: usize,
    ipcbuf: &'a mut IPCBuffer,
}

impl<'a> SendingImpl<'a> {
    fn new(ipcbuf: &'a mut IPCBuffer) -> Self {
        Self { cursor: 0, ipcbuf }
    }

    fn complete(ipcbuf: &mut IPCBuffer, message: &impl RPC) -> MessageInfo {
        let mut sending = SendingImpl::new(ipcbuf);
        message.send(&mut sending);
        let length = sending.cursor;
        MessageInfo::new(0, 0, 0, length as u64)
    }
}

impl<'a> Sending for SendingImpl<'a> {
    fn write_value(&mut self, value: ParameterValue) {
        self.ipcbuf.msg_regs_mut()[self.cursor] = value;
        self.cursor += 1;
    }
}

pub struct ReceivingIPC<'a> {
    pub ipcbuf: &'a IPCBuffer,
    pub info: MessageInfo,
    pub badge: Badge,
    receiving: ReceivingImpl<'a>,
}

impl<'a> ReceivingIPC<'a> {
    fn new(ipcbuf: &'a IPCBuffer, info: MessageInfo, badge: Badge) -> Self {
        Self {
            ipcbuf,
            info,
            badge,
            receiving: ReceivingImpl::new(ipcbuf, info.length() as usize),
        }
    }

    pub fn read<Output: RPC>(&mut self) -> Output {
        Output::recv(&mut self.receiving)
    }
}

#[derive(Clone)]
pub struct Client<Input> {
    endpoint: Endpoint,
    phantom: PhantomData<Input>,
}

impl<Input> Client<Input> {
    pub fn new(endpoint: Endpoint) -> Self {
        Self {
            endpoint,
            phantom: PhantomData,
        }
    }
}

impl<Input: RPC> Client<Input> {
    pub fn send(&self, input: &Input) {
        IPCBuffer::with_mut(|ipcbuf| self.send_with_ipcbuf(ipcbuf, input))
    }

    pub fn send_with_ipcbuf(&self, ipcbuf: &mut IPCBuffer, input: &Input) {
        let info = SendingImpl::complete(ipcbuf, input);
        self.endpoint.send(info);
    }

    pub fn call<Output: RPC>(&self, input: &Input) -> Output {
        IPCBuffer::with_mut(|ipcbuf| self.call_with_ipcbuf(ipcbuf, input))
    }

    pub fn call_with_ipcbuf<Output: RPC>(&self, ipcbuf: &mut IPCBuffer, input: &Input) -> Output {
        let send_info = SendingImpl::complete(ipcbuf, input);
        let recv_info = self.endpoint.call(send_info);
        ReceivingImpl::complete(ipcbuf, recv_info)
    }
}

pub mod server {
    use super::*;

    pub fn recv<F, T>(endpoint: Endpoint, f: F) -> T
    where
        F: FnOnce(ReceivingIPC) -> T,
    {
        IPCBuffer::with_mut(|ipcbuf| recv_with_ipcbuf(ipcbuf, endpoint, f))
    }

    pub fn recv_with_ipcbuf<F, T>(ipcbuf: &mut IPCBuffer, endpoint: Endpoint, f: F) -> T
    where
        F: FnOnce(ReceivingIPC) -> T,
    {
        let (info, badge) = endpoint.recv();
        let receiving = ReceivingIPC::new(ipcbuf, info, badge);
        f(receiving)
    }

    pub fn send<Output: RPC>(endpoint: Endpoint, output: &Output) {
        IPCBuffer::with_mut(|ipcbuf| send_with_ipcbuf(ipcbuf, endpoint, output))
    }

    pub fn send_with_ipcbuf<Output: RPC>(
        ipcbuf: &mut IPCBuffer,
        endpoint: Endpoint,
        output: &Output,
    ) {
        let info = SendingImpl::complete(ipcbuf, output);
        endpoint.send(info)
    }

    pub fn reply<Output: RPC>(output: &Output) {
        IPCBuffer::with_mut(|ipcbuf| reply_with_ipcbuf(ipcbuf, output))
    }

    pub fn reply_with_ipcbuf<Output: RPC>(ipcbuf: &mut IPCBuffer, output: &Output) {
        let info = SendingImpl::complete(ipcbuf, output);
        sel4::reply(info);
    }
}

pub mod proxy {
    use super::*;

    pub fn down(ipcbuf: &IPCBuffer, info: MessageInfo) -> &[u64] {
        &ipcbuf.msg_regs()[..info.length() as usize]
    }

    pub fn up(ipcbuf: &mut IPCBuffer, parameters: &[u64]) -> MessageInfo {
        ipcbuf.msg_regs_mut()[..parameters.len()].copy_from_slice(parameters);
        MessageInfo::new(0, 0, 0, parameters.len() as u64)
    }
}
