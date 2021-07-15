#![no_std]

extern crate alloc;

use alloc::collections::btree_map::BTreeMap;
use alloc::string::String;
use alloc::vec::Vec;
use serde::{Serialize, Deserialize};
use icecap_config::*;
use dyndl_types::ExternObj;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub lock: Notification,

    pub initialization_resources: ConfigRealmObjectInitializationResources,
    pub small_page: SmallPage,
    pub large_page: LargePage,

    pub allocator_cregion: ConfigCRegion,
    pub untyped: Vec<DynamicUntyped>,
    pub externs: ConfigExterns,

    pub host_bulk_region_start: usize,
    pub host_bulk_region_size: usize,

    pub cnode: CNode,
    pub local: Vec<Local>,
    pub secondary_threads: Vec<Thread>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Local {
    pub endpoint: Endpoint,
    pub reply_slot: Endpoint,
    pub timer_server_client: Endpoint,
    pub event_server_client: Endpoint,
    pub event_server_control: Endpoint,
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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DynamicUntyped {
    pub slot: Untyped,
    pub size_bits: usize,
    pub paddr: Option<usize>,
    pub device: bool,
}
