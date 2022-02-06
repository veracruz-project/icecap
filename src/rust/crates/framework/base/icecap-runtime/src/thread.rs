use alloc::boxed::Box;

#[cfg(feature = "serde1")]
use serde::{Deserialize, Serialize};

use icecap_sel4::{fast_send, prelude::*};

#[derive(Copy, Clone, Debug)]
#[cfg_attr(feature = "serde1", derive(Serialize, Deserialize))]
pub struct Thread(Endpoint);

impl From<Endpoint> for Thread {
    fn from(ep: Endpoint) -> Self {
        Self(ep)
    }
}

impl Thread {
    pub fn start(&self, f: impl FnOnce() + Send + 'static) {
        let b: Box<Box<dyn FnOnce() + 'static>> = Box::new(Box::new(f));
        let f_arg = Box::into_raw(b);
        fast_send(&self.0, 0, &[entry as Word, f_arg as Word, 0]);
    }
}

extern "C" fn entry(f_arg: u64) {
    let f = unsafe { Box::from_raw(f_arg as *mut Box<dyn FnOnce()>) };
    f();
}
