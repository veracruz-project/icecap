use icecap_core::sel4::sys::c_types;

mod c {
    use super::c_types;
    extern "C" {
        pub fn costub_startup();
        pub fn costub_alloc(size: usize, handle: *mut usize, buf: *mut *mut u8);
        pub fn costub_run_main(handle: usize) -> c_types::c_int;
    }
}

pub type Handle = usize;

pub struct Bytes {
    pub handle: Handle,
    pub buf: *mut u8,
    pub size: usize,
}

impl Bytes {
    pub fn as_slice(&self) -> &[u8] {
        unsafe { core::slice::from_raw_parts(self.buf, self.size) }
    }

    pub fn as_mut_slice(&self) -> &mut [u8] {
        unsafe { core::slice::from_raw_parts_mut(self.buf, self.size) }
    }
}

pub fn alloc(size: usize) -> Bytes {
    let mut handle = 0;
    let mut buf = core::ptr::null_mut();
    unsafe {
        c::costub_alloc(size, &mut handle, &mut buf);
    }
    Bytes { handle, buf, size }
}

pub fn run_main(arg: &[u8]) -> c_types::c_int {
    unsafe {
        c::costub_startup();
    }
    let bytes = alloc(arg.len());
    bytes.as_mut_slice().copy_from_slice(arg);
    unsafe { c::costub_run_main(bytes.handle) }
}
