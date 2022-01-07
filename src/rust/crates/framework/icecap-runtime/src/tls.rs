use icecap_sel4::prelude::*;
use icecap_sel4::sys;

use crate::c;

pub struct TlsRegion {
    base: usize,
    tpidr: u64,
}

impl TlsRegion {
    pub fn align() -> usize {
        unsafe { c::icecap_runtime_tls_region_align }
    }

    pub fn size() -> usize {
        unsafe { c::icecap_runtime_tls_region_size }
    }

    pub fn num_small_pages() -> usize {
        let size = Self::align() + Self::size(); // HACK
        let frame_size = FrameSize::Small.bytes();
        size / frame_size + if size % frame_size == 0 { 0 } else { 1 }
    }

    pub fn offset_into_first_page() -> usize {
        Self::align()
    }

    pub fn init(base: usize) -> Self {
        Self {
            base,
            tpidr: unsafe { c::icecap_runtime_tls_region_init(base) },
        }
    }

    pub fn insert_ipc_buffer(&self, ipc_buffer: usize) {
        unsafe { c::icecap_runtime_tls_region_insert_ipc_buffer(self.base, ipc_buffer) }
    }

    pub fn insert_tcb(&self, tcb: sys::seL4_CPtr) {
        unsafe { c::icecap_runtime_tls_region_insert_tcb(self.base, tcb) }
    }

    pub fn tpidr(&self) -> u64 {
        self.tpidr
    }
}
