use core::alloc::{GlobalAlloc, Layout};
use core::ptr;

use icecap_core::runtime;
use icecap_core::sync::{GenericMutex, unsafe_static_mutex};

struct IceCapAllocator;

unsafe_static_mutex!(Lock, icecap_runtime_heap_lock);

static DLMALLOC: GenericMutex<Lock, dlmalloc::Dlmalloc> = GenericMutex::new(Lock, dlmalloc::DLMALLOC_INIT);

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
        DLMALLOC.lock().realloc(ptr, layout.size(), layout.align(), new_size)
    }
}

#[no_mangle]
extern "C" fn icecap_dynamic_malloc(size: usize) -> *mut u8 {
    unsafe {
        DLMALLOC.lock().malloc(size, 8)
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
    crate::sel4::debug_println!("alloc error with layout: {:?}", layout);
    loop {
        runtime::exit()
    }
}
