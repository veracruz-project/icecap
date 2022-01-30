use core::alloc::Layout;

use icecap_core::sel4;
use icecap_core::runtime;
use icecap_dlmalloc::IceCapGlobalAllocator;

#[global_allocator]
static GLOBAL_ALLOCATOR: IceCapGlobalAllocator = IceCapGlobalAllocator;
    
#[alloc_error_handler]
fn alloc_error_handler(layout: Layout) -> ! {
    sel4::debug_println!("alloc error with layout: {:?}", layout);
    runtime::stop_component()
}
