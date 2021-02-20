#![no_std]

extern crate alloc;

use core::ops::Range;
use alloc::collections::btree_map::BTreeMap;
use alloc::string::String;
use serde::{Serialize, Deserialize};
use icecap_config_common::{sel4::prelude::*, DescTimerClient};
use icecap_qemu_ring_buffer_server_config::Client as QEMUClient;
use dyndl_types::ExternObj;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub spec: Option<Range<usize>>,
    pub my: ConfigMy,
    pub my_extra: ConfigMyExtra,
    pub externs: BTreeMap<String, ConfigExtern>,
    pub ctrl_ep_read: Endpoint,
    pub host: QEMUClient,
    pub timer: DescTimerClient,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConfigMy {
    pub cnode: CNode,
    pub asid_pool: ASIDPool,
    pub tcb_authority: TCB,
    pub pd: PGD,
    pub small_page_addr: usize,
    pub large_page_addr: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConfigMyExtra {
    pub small_page: SmallPage,
    pub large_page: LargePage,
    pub free_slot: u64,
    pub untyped: Untyped,
}

#[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize)]
pub struct ConfigExtern {
    pub ty: ExternObj,
    pub cptr: u64,
}
