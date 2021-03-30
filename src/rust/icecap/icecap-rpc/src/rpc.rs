use alloc::vec::Vec;
use crate::{ParameterValue, Parameter, ReadCall, WriteCall, call::SliceReader};

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

impl<T: Parameter> RPC for T {

    fn send(&self, call: &mut impl WriteCall) {
        call.write(*self)
    }

    fn recv(call: &mut impl ReadCall) -> Self {
        call.read()
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
