use core::mem::size_of;
use core::convert::TryInto;
use alloc::vec::Vec;
use serde::{Serialize, Deserialize};
use crate::{ParameterValue, ReadCall, WriteCall, call::SliceReader};

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

impl<T: Serialize + for<'a> Deserialize<'a>> RPC for T {

    fn send(&self, call: &mut impl WriteCall) {
        let mut bytes = postcard::to_allocvec(self).unwrap();
        let num_parameters = (bytes.len() + size_of::<ParameterValue>() - 1) / size_of::<ParameterValue>();
        bytes.resize_with(num_parameters * size_of::<ParameterValue>(), || 0);
        let chunks = bytes.chunks_exact(size_of::<ParameterValue>());
        assert_eq!(chunks.remainder().len(), 0);
        for chunk in chunks {
            call.write_value(ParameterValue::from_le_bytes(chunk.try_into().unwrap()))
        }
    }

    fn recv(call: &mut impl ReadCall) -> Self {
        let mut bytes = Vec::new();
        for _ in 0..call.remaining() {
            bytes.extend_from_slice(&call.read_value().to_le_bytes());
        }
        postcard::from_bytes(&bytes).unwrap()
    }
}
