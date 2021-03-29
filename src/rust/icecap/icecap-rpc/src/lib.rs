#![no_std]

extern crate alloc;

use alloc::collections::VecDeque;

pub type ParameterValue = u64;

pub trait ReadCall {

    fn read(&mut self) -> ParameterValue;
}

pub trait WriteCall {

    fn write(&mut self, value: ParameterValue);

    fn write_all(&mut self, values: &[ParameterValue]) {
        for value in values.iter() {
            self.write(*value);
        }
    }
}

pub trait RPC {

    fn send(&self, call: &mut impl WriteCall);

    fn recv(call: &mut impl ReadCall) -> Self;
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

impl ReadCall for VecDeque<ParameterValue> {

    fn read(&mut self) -> ParameterValue {
        self.pop_front().unwrap()
    }
}

impl WriteCall for VecDeque<ParameterValue> {

    fn write(&mut self, value: ParameterValue) {
        self.push_back(value)
    }
}
