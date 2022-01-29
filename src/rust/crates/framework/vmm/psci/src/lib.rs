#![no_std]

// TODO enrich
//  - request and response enums
//  - parsing from icecap_sel4::TCB
//  - etc.

pub const VERSION: i32 = 0x0001_0001;

pub const FID_PSCI_VERSION: u32 = 0x8400_0000;
pub const FID_CPU_ON: u32 = 0xC400_0003;
pub const FID_MIGRATE_INFO_TYPE: u32 = 0x8400_0006;
pub const FID_PSCI_FEATURES: u32 = 0x8400_000a;

pub const RET_SUCCESS: i32 = 0;
pub const RET_NOT_SUPPORTED: i32 = -1;
