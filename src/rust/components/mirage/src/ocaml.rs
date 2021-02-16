use icecap_std::sys::c_types::*;
use crate::c;

pub fn run(arg: &[u8]) -> c_int {
    unsafe {
        c::costub_startup();
    }
    let mut handle = 0;
    let mut buf = core::ptr::null_mut();
    unsafe {
        c::costub_alloc(arg.len(), &mut handle, &mut buf);
    }
    let raw_arg = unsafe {
        core::slice::from_raw_parts_mut(buf, arg.len())
    };
    raw_arg.copy_from_slice(arg);
    unsafe {
        c::costub_run_main(handle)
    }
}
