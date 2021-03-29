#![no_std]

extern crate alloc;

use alloc::vec::Vec;

pub type ParameterValue = u64;

pub trait Parameter {

    fn into_value(self) -> ParameterValue;

    fn from_value(value: ParameterValue) -> Self;
}

impl Parameter for u64 {

    fn into_value(self) -> ParameterValue {
        self
    }

    fn from_value(value: ParameterValue) -> Self {
        value
    }
}

impl Parameter for usize {

    fn into_value(self) -> ParameterValue {
        self as ParameterValue
    }

    fn from_value(value: ParameterValue) -> Self {
        value as Self
    }
}

impl Parameter for i64 {

    fn into_value(self) -> ParameterValue {
        self as ParameterValue
    }

    fn from_value(value: ParameterValue) -> Self {
        value as Self
    }
}

impl Parameter for i32 {

    fn into_value(self) -> ParameterValue {
        self as ParameterValue
    }

    fn from_value(value: ParameterValue) -> Self {
        value as Self
    }
}

pub trait ReadCall {

    fn read_value(&mut self) -> ParameterValue;

    fn read<T: Parameter>(&mut self) -> T {
        T::from_value(self.read_value())
    }
}

pub trait WriteCall {

    fn write_value(&mut self, value: ParameterValue);

    fn write<T: Parameter>(&mut self, value: T) {
        self.write_value(value.into_value())
    }

    fn write_all(&mut self, values: &[ParameterValue]) {
        for value in values.iter() {
            self.write(*value);
        }
    }
}

pub trait RPC: Sized {

    fn send(&self, call: &mut impl WriteCall);

    fn recv(call: &mut impl ReadCall) -> Self;

    fn send_to_vec(&self) -> Vec<ParameterValue> {
        let mut call = Vec::new();
        self.send(&mut call);
        call
    }

    fn recv_from_slice(parameters: &[ParameterValue]) -> Self {
        Self::recv(&mut SliceReader {
            unread: parameters,
        })
    }
}

impl RPC for () {

    fn send(&self, _call: &mut impl WriteCall) {
    }

    fn recv(_call: &mut impl ReadCall) -> Self {
        ()
    }
}

impl<T: RPC, E: RPC> RPC for Result<T, E> {

    fn send(&self, call: &mut impl WriteCall) {
        match self {
            Ok(v) => {
                call.write(0);
                v.send(call);
            }
            Err(v) => {
                call.write(1);
                v.send(call);
            }
        }
    }

    fn recv(call: &mut impl ReadCall) -> Self {
        match call.read() {
            0 => Ok(T::recv(call)),
            1 => Err(E::recv(call)),
            _ => panic!(),
        }
    }
}

struct SliceReader<'a> {
    unread: &'a [ParameterValue],
}

impl ReadCall for SliceReader<'_> {

    fn read_value(&mut self) -> ParameterValue {
        let v = self.unread[0];
        self.unread = &self.unread[1..];
        v
    }
}

impl WriteCall for Vec<ParameterValue> {

    fn write_value(&mut self, value: ParameterValue) {
        self.push(value)
    }
}
