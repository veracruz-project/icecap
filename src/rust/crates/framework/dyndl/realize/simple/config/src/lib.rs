#![no_std]

extern crate alloc;

use alloc::collections::btree_map::BTreeMap;
use alloc::string::String;
use alloc::vec::Vec;

use serde::{Deserialize, Serialize};

use dyndl_types::ExternObj;
use icecap_config::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RealizerConfig {
    pub initialization_resources: SubsystemObjectInitializationResourcesConfig,
    pub small_page: SmallPage,
    pub large_page: LargePage,

    pub allocator_cregion: CRegionConfig,
    pub untyped: Vec<DynamicUntyped>,
    pub externs: ExternsConfig,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SubsystemObjectInitializationResourcesConfig {
    pub pgd: PGD,
    pub asid_pool: ASIDPool,
    pub tcb_authority: TCB,
    pub small_page_addr: usize,
    pub large_page_addr: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CRegionConfig {
    pub root: RelativeCPtrConfig,
    pub guard: u64,
    pub guard_size: u64,
    pub slots_size_bits: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RelativeCPtrConfig {
    pub root: CNode,
    pub cptr: CPtr,
    pub depth: usize,
}

pub type ExternsConfig = BTreeMap<String, ExternsConfigEntry>;

#[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize)]
pub struct ExternsConfigEntry {
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
