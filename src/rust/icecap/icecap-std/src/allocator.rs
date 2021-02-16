use core::alloc::{GlobalAlloc, Layout};
use core::ptr;

use icecap_core::runtime;

struct IceCapAllocator;

// TODO sync with icecap_runtime_heap_lock

static mut DLMALLOC: dlmalloc::Dlmalloc = dlmalloc::DLMALLOC_INIT;

unsafe impl GlobalAlloc for IceCapAllocator {
    #[inline]
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        DLMALLOC.malloc(layout.size(), layout.align())
    }

    #[inline]
    unsafe fn alloc_zeroed(&self, layout: Layout) -> *mut u8 {
        DLMALLOC.calloc(layout.size(), layout.align())
    }

    #[inline]
    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        DLMALLOC.free(ptr, layout.size(), layout.align())
    }

    #[inline]
    unsafe fn realloc(&self, ptr: *mut u8, layout: Layout, new_size: usize) -> *mut u8 {
        DLMALLOC.realloc(ptr, layout.size(), layout.align(), new_size)
    }
}

#[no_mangle]
extern "C" fn icecap_dynamic_malloc(size: usize) -> *mut u8 {
    unsafe {
        DLMALLOC.malloc(size, 8)
    }
}

#[no_mangle]
extern "C" fn icecap_dynamic_free(_ptr: *mut u8) -> *mut u8 {
    // panic!()
    ptr::null_mut()
}

#[global_allocator]
static GLOBAL_ALLOCATOR: IceCapAllocator = IceCapAllocator;

#[alloc_error_handler]
fn alloc_error_handler(layout: core::alloc::Layout) -> ! {
    crate::println!("alloc error with layout: {:?}", layout);
    loop {
        runtime::exit()
    }
}
