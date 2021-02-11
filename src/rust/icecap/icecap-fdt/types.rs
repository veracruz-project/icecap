use alloc::prelude::v1::*;
use alloc::collections::BTreeMap;

pub(crate) const MAGIC: u32 = 0xd00dfeed;
pub(crate) const HEADER_SIZE: usize = 10 * 4;

pub(crate) const VERSION: u32 = 17;
pub(crate) const LAST_COMP_VERSION: u32 = 16;

pub(crate) const TOK_BEGIN_NODE: u32 = 1;
pub(crate) const TOK_END_NODE: u32 = 2;
pub(crate) const TOK_PROP: u32 = 3;
pub(crate) const TOK_NOP: u32 = 4;
pub(crate) const TOK_END: u32 = 9;

#[derive(Debug)]
pub(crate) struct Header {
    pub magic: u32,
    pub totalsize: u32,
    pub off_dt_struct: u32,
    pub off_dt_strings: u32,
    pub off_mem_rsvmap: u32,
    pub version: u32,
    pub last_comp_version: u32,
    pub boot_cpuid_phys: u32,
    pub size_dt_strings: u32,
    pub size_dt_struct: u32,
}

#[derive(Debug)]
pub(crate) struct PropHeader {
    pub len: u32,
    pub name_off: u32,
}

#[derive(Eq, PartialEq, Debug)]
pub struct DeviceTree {
    pub mem_rsvmap: Vec<ReserveEntry>,
    pub root: Node,
    pub boot_cpuid_phys: u32,
}

#[derive(Eq, PartialEq, Debug)]
pub struct ReserveEntry {
    pub address: u64,
    pub size: u64,
}

#[derive(Eq, PartialEq, Debug)]
pub struct Node {
    pub properties: BTreeMap<String, Value>,
    pub children: BTreeMap<String, Box<Node>>,
}

#[derive(Eq, PartialEq, Debug)]
pub struct Value {
    pub raw: Vec<u8>,
}

impl Node {
    pub fn new() -> Self {
        Self {
            properties: BTreeMap::new(),
            children: BTreeMap::new(),
        }
    }
}

impl Value {
    pub fn new(raw: Vec<u8>) -> Self {
        Self { raw }
    }
}
