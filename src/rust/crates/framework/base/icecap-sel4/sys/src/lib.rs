#![no_std]
#![feature(thread_local)]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]
#![allow(non_upper_case_globals)]

pub mod c_types {
    pub type c_char = u8;
    pub type c_schar = i8;
    pub type c_uchar = u8;
    pub type c_short = i16;
    pub type c_ushort = u16;
    pub type c_int = i32;
    pub type c_uint = u32;
    pub type c_long = i64;
    pub type c_ulong = u64;
    pub type c_longlong = i64;
    pub type c_ulonglong = u64;
    pub use core::ffi::c_void;
}

include!(concat!(env!("OUT_DIR"), "/bindings.rs"));

// bindgen doesn't support thead-local symbols
extern "C" {
    #[thread_local]
    pub static mut __sel4_ipc_buffer: *mut seL4_IPCBuffer;
}
