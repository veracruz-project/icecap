use icecap_std::sys::c_types::*;

extern "C" {
    pub fn costub_startup();
    pub fn costub_alloc(size: usize, handle: *mut usize, buf: *mut *mut u8);
    pub fn costub_run_main(handle: usize) -> c_int;
}
