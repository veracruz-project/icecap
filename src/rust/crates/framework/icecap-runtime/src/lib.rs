#![no_std]
#![feature(thread_local)]

// TODO split into with-alloc and without-alloc parts
extern crate alloc;

mod c;
mod thread;
mod tls;
mod debug;

use icecap_sel4::{TCB, LocalCPtr};

pub use thread::Thread;
pub use tls::TlsRegion;
pub use debug::{image_path, text, eh_frame_hdr, eh_frame_end};

#[deprecated(note="Use ::stop_component() instead of ::exit()")]
pub use crate::stop_component as exit;

pub fn stop_thread() -> ! {
    unsafe {
        c::icecap_runtime_stop_thread()
    }
}

pub fn stop_component() -> ! {
    unsafe {
        c::icecap_runtime_stop_component()
    }
}

pub fn tcb() -> TCB {
    TCB::from_raw(unsafe {
        c::icecap_runtime_tcb
    })
}
