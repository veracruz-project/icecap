use crate::{Supervisor, sel4::Endpoint};

extern "C" {
    static icecap_runtime_supervisor_ep: u64;
}

#[inline]
pub fn supervisor() -> Supervisor {
    Supervisor::new(Endpoint::from_raw(unsafe {
        icecap_runtime_supervisor_ep
    }))
}
