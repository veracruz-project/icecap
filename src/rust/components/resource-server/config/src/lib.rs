#![no_std]

extern crate alloc;

use alloc::collections::btree_map::BTreeMap;
use alloc::string::String;
use alloc::vec::Vec;
use serde::{Serialize, Deserialize};
use icecap_config::{sel4::prelude::*, DescTimerClient, DescMappedRingBuffer, DynamicUntyped};
use dyndl_types::ExternObj;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub initialization_resources: ConfigRealmObjectInitializationResources,
    pub small_page: SmallPage,
    pub large_page: LargePage,

    pub allocator_cregion: ConfigCRegion,
    pub untyped: Vec<DynamicUntyped>,
    pub externs: ConfigExterns,

    pub host_ep_read: Endpoint,
    pub host_rb: DescMappedRingBuffer,
    pub timer: DescTimerClient,
    pub ctrl_ep_read: Endpoint,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConfigRealmObjectInitializationResources {
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