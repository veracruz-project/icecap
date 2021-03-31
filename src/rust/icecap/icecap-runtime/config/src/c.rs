use alloc::vec::Vec;
use serde::{Serialize, Deserialize};

#[repr(C)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HeapInfo {
    pub start: u64,
    pub end: u64,
    pub lock: u64,
}

#[repr(C)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EhInfo {
    pub text_start: u64,
    pub text_end: u64,
    pub eh_frame_hdr_start: u64,
    pub eh_frame_hdr_end: u64,
    pub eh_frame_end: u64,
    pub image_path_offset: u64,
}

#[repr(C)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TlsImage {
    pub vaddr: u64,
    pub filesz: u64,
    pub memsz: u64,
    pub align: u64,
}

#[repr(C)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Arg {
    pub offset: u64,
    pub size: u64,
}

#[repr(C)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommonConfig {
    pub heap_info: HeapInfo,
    pub eh_info: EhInfo,
    pub tls_image: TlsImage,
    pub arg: Arg,
    pub fault_handling: u64,
    pub print_lock: u64,
    pub supervisor_ep: u64,
}

#[repr(C)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ThreadConfig {
    pub ipc_buffer: u64,
    pub endpoint: u64,
    pub tcb: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub common: CommonConfig,
    pub threads: Vec<ThreadConfig>,
}
