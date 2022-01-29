use icecap_core::sel4::sys::c_types;

mod c {
    use super::c_types;
    extern "C" {
        pub fn costub_startup();
        pub fn costub_alloc(size: usize, handle: *mut usize, buf: *mut *mut u8);
        pub fn costub_run_main(handle: usize) -> c_types::c_int;
    }
}

pub fn run_ocaml(arg: &[u8]) -> c_types::c_int {
    unsafe {
        c::costub_startup();
    }
    let mut handle = 0;
    let mut buf = core::ptr::null_mut();
    unsafe {
        c::costub_alloc(arg.len(), &mut handle, &mut buf);
    }
    let raw_arg = unsafe { core::slice::from_raw_parts_mut(buf, arg.len()) };
    raw_arg.copy_from_slice(arg);
    unsafe { c::costub_run_main(handle) }
}
