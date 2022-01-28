use core::alloc::{GlobalAlloc, Layout};

use icecap_core::sync::{unsafe_static_mutex, GenericMutex};
use icecap_core::{runtime, sel4};

struct IceCapAllocator;

unsafe_static_mutex!(Lock, icecap_runtime_heap_lock);

static DLMALLOC: GenericMutex<Lock, dlmalloc::Dlmalloc> =
    GenericMutex::new(Lock, dlmalloc::DLMALLOC_INIT);

unsafe impl GlobalAlloc for IceCapAllocator {
    #[inline]
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        DLMALLOC.lock().malloc(layout.size(), layout.align())
    }

    #[inline]
    unsafe fn alloc_zeroed(&self, layout: Layout) -> *mut u8 {
        DLMALLOC.lock().calloc(layout.size(), layout.align())
    }

    #[inline]
    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        DLMALLOC.lock().free(ptr, layout.size(), layout.align())
    }

    #[inline]
    unsafe fn realloc(&self, ptr: *mut u8, layout: Layout, new_size: usize) -> *mut u8 {
        DLMALLOC
            .lock()
            .realloc(ptr, layout.size(), layout.align(), new_size)
    }
}

#[global_allocator]
static GLOBAL_ALLOCATOR: IceCapAllocator = IceCapAllocator;

#[alloc_error_handler]
fn alloc_error_handler(layout: core::alloc::Layout) -> ! {
    sel4::debug_println!("alloc error with layout: {:?}", layout);
    runtime::stop_component()
}
