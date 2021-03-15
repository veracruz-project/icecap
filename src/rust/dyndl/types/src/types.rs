use alloc::vec::Vec;
use core::convert::TryFrom;
use alloc::string::String;
use alloc::collections::btree_map::BTreeMap;
use serde::{Serialize, Deserialize};
use dyndl_types_derive::{IsCap, IsObj};

pub type ObjId = usize;

#[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize)]
pub enum Obj {
    Untyped(obj::Untyped),
    Endpoint,
    Notification,
    CNode(obj::CNode),
    TCB(obj::TCB),
    VCPU,
    SmallPage(obj::SmallPage),
    LargePage(obj::LargePage),
    PT(obj::PT),
    PD(obj::PD),
    PUD(obj::PUD),
    PGD(obj::PGD),
}

#[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize)]
pub enum Cap {
    Untyped(cap::Untyped),
    Endpoint(cap::Endpoint),
    Notification(cap::Notification),
    CNode(cap::CNode),
    TCB(cap::TCB),
    VCPU(cap::VCPU),
    SmallPage(cap::SmallPage),
    LargePage(cap::LargePage),
    PT(cap::PT),
    PD(cap::PD),
    PUD(cap::PUD),
    PGD(cap::PGD),
}

pub type Badge = u64;

#[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize)]
pub struct Rights {
    pub read: bool,
    pub write: bool,
    pub grant: bool,
    pub grant_reply: bool,
}

type CPtr = u64;
pub type Table<T> = BTreeMap<usize, T>;
pub type Fill = Vec<FillEntry>;

#[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize)]
pub struct FillEntry {
    pub offset: usize,
    pub length: usize,
    pub content: Vec<u8>,
    pub file: String,
    pub file_offset: usize,
}

#[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize)]
pub enum PDEntry {
    PT(cap::PT),
    LargePage(cap::LargePage),
}

pub mod obj {
    use super::*;

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsObj)]
    pub struct Untyped {
        pub size_bits: usize,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsObj)]
    pub struct CNode {
        pub size_bits: usize,
        pub entries: Table<Cap>,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsObj)]
    pub struct TCB {
        pub fault_ep: CPtr,
        pub cspace: cap::CNode,
        pub vspace: cap::PGD,
        pub ipc_buffer: cap::SmallPage,
        pub ipc_buffer_addr: u64,
        pub vcpu: Option<cap::VCPU>,

        pub affinity: u64,
        pub prio: u8,
        pub max_prio: u8,
        pub resume: bool,

        pub ip: u64,
        pub sp: u64,
        pub spsr: u64,
        pub gprs: Vec<u64>,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsObj)]
    pub struct SmallPage {
        pub fill: Fill,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsObj)]
    pub struct LargePage {
        pub fill: Fill,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsObj)]
    pub struct PT {
        pub entries: Table<cap::SmallPage>
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsObj)]
    pub struct PD {
        pub entries: Table<PDEntry>
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsObj)]
    pub struct PUD {
        pub entries: Table<cap::PD>
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsObj)]
    pub struct PGD {
        pub entries: Table<cap::PUD>
    }

}

pub mod cap {
    use super::*;

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsCap)]
    pub struct Untyped {
        pub obj: ObjId,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsCap)]
    pub struct Endpoint {
        pub obj: ObjId,
        pub badge: Badge,
        pub rights: Rights,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsCap)]
    pub struct Notification {
        pub obj: ObjId,
        pub badge: Badge,
        pub rights: Rights,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsCap)]
    pub struct CNode {
        pub obj: ObjId,
        pub guard: u64,
        pub guard_size: u64,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsCap)]
    pub struct TCB {
        pub obj: ObjId,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsCap)]
    pub struct VCPU {
        pub obj: ObjId,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsCap)]
    pub struct SmallPage {
        pub obj: ObjId,
        pub rights: Rights,
        pub cached: bool,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsCap)]
    pub struct LargePage {
        pub obj: ObjId,
        pub rights: Rights,
        pub cached: bool,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsCap)]
    pub struct PT {
        pub obj: ObjId,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsCap)]
    pub struct PD {
        pub obj: ObjId,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsCap)]
    pub struct PUD {
        pub obj: ObjId,
    }

    #[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize, IsCap)]
    pub struct PGD {
        pub obj: ObjId,
    }

}

#[derive(Debug, Clone, Copy, Eq, PartialEq, Serialize, Deserialize)]
pub enum ExternObj {
    Endpoint,
    Notification,
    SmallPage,
    LargePage,
}

#[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize)]
pub struct Model {
    pub objects: Vec<TopObj>
}

#[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize)]
pub enum AnyObj {
    Local(Obj),
    Extern(ExternObj),
}

#[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize)]
pub struct TopObj {
    pub object: AnyObj,
    pub name: String,
}
