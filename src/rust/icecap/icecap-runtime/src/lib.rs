#![no_std]
#![feature(thread_local)]

// TODO split into with-alloc and without-alloc parts
extern crate alloc;

use alloc::boxed::Box;
use serde::{Serialize, Deserialize};

use icecap_sel4::*;

extern "C" {
    #[thread_local]
    static icecap_runtime_tcb: u64;

    fn icecap_runtime_exit() -> !;

    static icecap_runtime_tls_region_align: usize;
    static icecap_runtime_tls_region_size: usize;
    fn icecap_runtime_tls_region_init(tls_region: usize) -> u64;
    fn icecap_runtime_tls_region_insert_ipc_buffer(dst_tls_region: usize, ipc_buffer: usize);
    fn icecap_runtime_tls_region_insert_tcb(dst_tls_region: usize, tcb: u64);
}

pub fn exit() -> ! {
    unsafe {
        icecap_runtime_exit()
    }
}

pub fn tcb() -> TCB {
    TCB::from_raw(unsafe {
        icecap_runtime_tcb
    })
}

pub struct TLSRegion {
    base: usize,
    tpidr: u64,
}

impl TLSRegion {


    pub fn align() -> usize {
        unsafe {
            icecap_runtime_tls_region_align
        }
    }

    pub fn size() -> usize {
        unsafe {
            icecap_runtime_tls_region_size
        }
    }

    pub fn num_pages() -> usize {
        let size = Self::align() + Self::size(); // HACK
        size / 4096 + if size % 4096 == 0 { 0 } else { 1 }
    }

    pub fn offset_into_first_page() -> usize {
        Self::align()
    }

    pub fn init(base: usize) -> Self {
        Self {
            base,
            tpidr: unsafe {
                icecap_runtime_tls_region_init(base)
            },
        }
    }

    pub fn insert_ipc_buffer(&self, ipc_buffer: usize) {
        unsafe {
            icecap_runtime_tls_region_insert_ipc_buffer(self.base, ipc_buffer)
        }
    }

    pub fn insert_tcb(&self, tcb: u64) {
        unsafe {
            icecap_runtime_tls_region_insert_tcb(self.base, tcb)
        }
    }

    pub fn tpidr(&self) -> u64 {
        self.tpidr
    }

}

#[derive(Copy, Clone, Debug, Serialize, Deserialize)]
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
        MR_2.set(0);
        self.0.send(MessageInfo::new(0, 0, 0, 3))
    }

}

extern "C" fn entry(f_arg: u64) {
     let f = unsafe {
         Box::from_raw(f_arg as *mut Box<dyn FnOnce()>)
     };
     f();
     // TODO
     exit();
}
