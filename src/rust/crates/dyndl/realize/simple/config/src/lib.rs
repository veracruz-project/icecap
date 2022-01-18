#![no_std]

extern crate alloc;

use alloc::collections::btree_map::BTreeMap;
use alloc::string::String;
use alloc::vec::Vec;

use serde::{Deserialize, Serialize};

use dyndl_types::ExternObj;
use icecap_config::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConfigRealizer {
    pub initialization_resources: ConfigSubsystemObjectInitializationResources,
    pub small_page: SmallPage,
    pub large_page: LargePage,

    pub allocator_cregion: ConfigCRegion,
    pub untyped: Vec<DynamicUntyped>,
    pub externs: ConfigExterns,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConfigSubsystemObjectInitializationResources {
    pub pgd: PGD,
    pub asid_pool: ASIDPool,
    pub tcb_authority: TCB,
    pub small_page_addr: usize,
    pub large_page_addr: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConfigCRegion {
    pub root: ConfigRelativeCPtr,
    pub guard: u64,
    pub guard_size: u64,
    pub slots_size_bits: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConfigRelativeCPtr {
    pub root: CNode,
    pub cptr: CPtr,
    pub depth: usize,
}

pub type ConfigExterns = BTreeMap<String, ConfigExtern>;

#[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize)]
pub struct ConfigExtern {
    pub ty: ExternObj,
    pub cptr: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DynamicUntyped {
    pub slot: Untyped,
    pub size_bits: usize,
    pub paddr: Option<usize>,
    pub device: bool,
}
