use serde::{Deserialize, Serialize};

#[repr(C)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HeapInfo {
    pub start: u64,
    pub end: u64,
    pub lock: u64,
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
    pub tls_image: TlsImage,
    pub arg: Arg,
    pub image_path_offset: u64,
    pub print_lock: u64,
    pub idle_notification: u64,
}

#[repr(C)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ThreadConfig {
    pub ipc_buffer: u64,
    pub endpoint: u64,
    pub tcb: u64,
}
