use icecap_std::sys::c_types::*;

extern "C" {
    pub fn costub_run_mirage() -> c_int;
    pub fn costub_alloc(size: usize, handle: *mut usize, buf: *mut *mut u8);
}
