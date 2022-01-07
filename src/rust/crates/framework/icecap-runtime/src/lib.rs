#![no_std]
#![feature(thread_local)]

// TODO split into with-alloc and without-alloc parts
extern crate alloc;

mod c;
mod thread;
mod tls;
mod debug;

use icecap_sel4::{TCB, Endpoint, LocalCPtr};

pub use thread::Thread;
pub use tls::TlsRegion;
pub use debug::{image_path, text, eh_frame_hdr, eh_frame_end};

pub fn exit() -> ! {
    unsafe {
        c::icecap_runtime_exit()
    }
}

pub fn tcb() -> TCB {
    TCB::from_raw(unsafe {
        c::icecap_runtime_tcb
    })
}

pub fn supervisor() -> Endpoint {
    Endpoint::from_raw(unsafe {
        c::icecap_runtime_supervisor_endpoint
    })
}
