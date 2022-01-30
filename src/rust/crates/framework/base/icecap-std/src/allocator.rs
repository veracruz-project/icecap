use core::alloc::{GlobalAlloc, Layout};
use core::ptr;

use dlmalloc::{Dlmalloc, Allocator as DlmallocAllocator};

use icecap_core::sync::{unsafe_static_mutex, GenericMutex};
use icecap_core::{runtime, sel4};

extern "C" {
    static mut icecap_runtime_heap_start: usize;
    static icecap_runtime_heap_end: usize;
}

unsafe_static_mutex!(Lock, icecap_runtime_heap_lock);

static GLOBAL_DLMALLOC: GenericMutex<Lock, Dlmalloc<IceCapSystemAllocator>> =
    GenericMutex::new(Lock, Dlmalloc::new_with_allocator(IceCapSystemAllocator));

#[global_allocator]
static GLOBAL_ALLOCATOR: IceCapGlobalAllocator = IceCapGlobalAllocator;
    
#[alloc_error_handler]
fn alloc_error_handler(layout: core::alloc::Layout) -> ! {
    sel4::debug_println!("alloc error with layout: {:?}", layout);
    runtime::stop_component()
}

struct IceCapGlobalAllocator;

unsafe impl GlobalAlloc for IceCapGlobalAllocator {
    #[inline]
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        GLOBAL_DLMALLOC.lock().malloc(layout.size(), layout.align())
    }

    #[inline]
    unsafe fn alloc_zeroed(&self, layout: Layout) -> *mut u8 {
        GLOBAL_DLMALLOC.lock().calloc(layout.size(), layout.align())
    }

    #[inline]
    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        GLOBAL_DLMALLOC.lock().free(ptr, layout.size(), layout.align())
    }

    #[inline]
    unsafe fn realloc(&self, ptr: *mut u8, layout: Layout, new_size: usize) -> *mut u8 {
        GLOBAL_DLMALLOC
            .lock()
            .realloc(ptr, layout.size(), layout.align(), new_size)
    }
}

struct IceCapSystemAllocator;

unsafe impl DlmallocAllocator for IceCapSystemAllocator {

    fn alloc(&self, size: usize) -> (*mut u8, usize, u32) {
        unsafe {
            let addr = icecap_runtime_heap_start;
            icecap_runtime_heap_start += size;
            if icecap_runtime_heap_start > icecap_runtime_heap_end {
                (ptr::null_mut(), 0, 0)
            } else {
                (addr as *mut u8, size, 0)
            }
        }
    }

    fn remap(&self, _ptr: *mut u8, _oldsize: usize, _newsize: usize, _can_move: bool) -> *mut u8 {
        ptr::null_mut()
    }

    fn free_part(&self, _ptr: *mut u8, _oldsize: usize, _newsize: usize) -> bool {
        false
    }

    fn free(&self, _ptr: *mut u8, _size: usize) -> bool {
        false
    }

    fn can_release_part(&self, _flags: u32) -> bool {
        false
    }

    fn allocates_zeros(&self) -> bool {
        true
    }

    fn page_size(&self) -> usize {
        4096
    }
}
