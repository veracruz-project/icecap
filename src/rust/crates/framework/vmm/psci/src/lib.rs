#![no_std]

use icecap_sel4::fault::UnknownSyscall;

pub const SYS_PSCI: u64 = 0;

pub const VERSION: i32 = 0x0001_0001;

pub const FID_PSCI_VERSION: u32 = 0x8400_0000;
pub const FID_CPU_ON: u32 = 0xC400_0003;
pub const FID_MIGRATE_INFO_TYPE: u32 = 0x8400_0006;
pub const FID_PSCI_FEATURES: u32 = 0x8400_000a;

pub const RET_SUCCESS: i32 = 0;
pub const RET_NOT_SUPPORTED: i32 = -1;

pub enum Call {
    Version,
    Features { qfid: u32 },
    CpuOn { target: usize, entry: u64, ctx_id: u64 },
    MigrateInfoType,
}

impl Call {

    
    pub fn parse(fault: &UnknownSyscall) -> Result<Self, CallParseError> {
        let fid = fault.x0 as u32;
        Ok(match fid {
            FID_PSCI_VERSION => Self::Version,
            FID_PSCI_FEATURES => Self::Features {
                qfid: fault.x1 as u32,
            },
            FID_CPU_ON => Self::CpuOn {
                target: fault.x1 as usize,
                entry: fault.x2 as u64,
                ctx_id: fault.x3 as u64,
            },
            FID_MIGRATE_INFO_TYPE => Self::MigrateInfoType,
            _ => {
                return Err(CallParseError::UnrecognizedFid { fid })
            }
        })
    }
}

#[derive(Debug)]
pub enum CallParseError {
    UnrecognizedFid { fid: u32 },
}
