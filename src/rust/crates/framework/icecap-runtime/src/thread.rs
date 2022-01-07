use icecap_sel4::prelude::*;

use alloc::boxed::Box;
#[cfg(feature = "serde1")]
use serde::{Serialize, Deserialize};

#[derive(Copy, Clone, Debug)]
#[cfg_attr(feature = "serde1", derive(Serialize, Deserialize))]
pub struct Thread(Endpoint);

impl From<Endpoint> for Thread {
    fn from(ep: Endpoint) -> Self {
        Self(ep)
    }
}

// TODO join
impl Thread {

    pub fn start(&self, f: impl FnOnce() + Send + 'static) {
        let b: Box<Box<dyn FnOnce() + 'static>> = Box::new(Box::new(f));
        let f_arg = Box::into_raw(b);
        MR_0.set(entry as Word);
        MR_1.set(f_arg as Word);
        MR_2.set(self.0.raw() as Word);
        self.0.send(MessageInfo::new(0, 0, 0, 3))
    }

}

extern "C" fn entry(f_arg: u64, own_ep: u64) {
    let f = unsafe {
        Box::from_raw(f_arg as *mut Box<dyn FnOnce()>)
    };
    f();
    // HACK
    loop {
        Endpoint::from_raw(own_ep).recv();
    }
}
