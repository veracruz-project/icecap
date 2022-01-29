use alloc::vec::Vec;
use core::convert::TryInto;
use core::mem::size_of;

use serde::{Deserialize, Serialize};

use crate::{transit::SliceReader, ParameterValue, Receiving, Sending};

pub trait RPC: Sized {
    fn send(&self, sending: &mut impl Sending);

    fn recv(receiving: &mut impl Receiving) -> Self;

    fn send_to_vec(&self) -> Vec<ParameterValue> {
        let mut sending = Vec::new();
        self.send(&mut sending);
        sending
    }

    fn recv_from_slice(parameters: &[ParameterValue]) -> Self {
        Self::recv(&mut SliceReader { unread: parameters })
    }
}

// Convenient, by rust-specific and slow
impl<T: Serialize + for<'a> Deserialize<'a>> RPC for T {
    fn send(&self, sending: &mut impl Sending) {
        let mut bytes = postcard::to_allocvec(self).unwrap();
        let num_parameters =
            (bytes.len() + size_of::<ParameterValue>() - 1) / size_of::<ParameterValue>();
        bytes.resize_with(num_parameters * size_of::<ParameterValue>(), || 0);
        let chunks = bytes.chunks_exact(size_of::<ParameterValue>());
        assert_eq!(chunks.remainder().len(), 0);
        for chunk in chunks {
            sending.write_value(ParameterValue::from_le_bytes(chunk.try_into().unwrap()))
        }
    }

    fn recv(receiving: &mut impl Receiving) -> Self {
        let mut bytes = Vec::new();
        for _ in 0..receiving.remaining() {
            bytes.extend_from_slice(&receiving.read_value().to_le_bytes());
        }
        postcard::from_bytes(&bytes).unwrap()
    }
}
