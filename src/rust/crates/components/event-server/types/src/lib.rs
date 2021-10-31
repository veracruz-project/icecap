#![no_std]
#![feature(type_ascription)]

use core::sync::atomic::{AtomicU64, Ordering};
use serde::{Serialize, Deserialize};

use biterate::biterate;
use finite_set::*;

pub type RealmId = usize;
pub type NodeIndex = usize;
pub type OutIndex = usize;
pub type InIndex = usize;

#[derive(Clone)]
pub struct Bitfield {
    addr: usize
}

impl Bitfield {

    const GROUP_BITS: u32 = 64;

    pub unsafe fn new(addr: usize) -> Self {
        Self {
            addr,
        }
    }

    fn group(&self, group_index: u32) -> &AtomicU64 {
        unsafe {
            &*((self.addr + core::mem::size_of::<u64>() * (group_index as usize)) as *const AtomicU64)
        }
    }

    pub fn set(&self, bit: u32) -> /* notify: */ bool {
        let group_index = bit / Self::GROUP_BITS;
        let member_index = bit % Self::GROUP_BITS;
        let member = 1 << member_index;
        let old = self.group(group_index).fetch_or(member, Ordering::SeqCst);
        old & member == 0
    }

    pub fn clear<E>(&self, badge: u64, mut f: impl FnMut(/* bit: */ u32) -> Result<(), E>) -> Result<(), E> {
        for group_index in biterate(badge) {
            let members = self.group(group_index).swap(0, Ordering::SeqCst);
            for member_index in biterate(members) {
                let bit = group_index * Self::GROUP_BITS + member_index;
                f(bit)?;
            }
        }
        Ok(())
    }

    pub fn clear_ignore(&self, badge: u64) {
        self.clear(badge, |_| (Ok(()): Result<(), ()>)).unwrap();
    }

    pub fn clear_ignore_all(&self) {
        self.clear_ignore(!0u64)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ConfigureAction {
    SetEnabled(bool),
    SetPriority(usize),
}

pub mod calls {
    use super::*;

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub enum Client {
        Signal { index: OutIndex },
        SEV { nid: NodeIndex },
        Poll { nid: NodeIndex },
        End { nid: NodeIndex, index: InIndex },
        Configure { nid: NodeIndex, index: InIndex, action: ConfigureAction },
        Move { src_nid: NodeIndex, src_index: InIndex, dst_nid: NodeIndex, dst_index: InIndex },
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub enum ResourceServer {
        Subscribe { nid: NodeIndex, host_nid: NodeIndex },
        Unsubscribe { nid: NodeIndex, host_nid: NodeIndex },
        CreateRealm { realm_id: RealmId, num_nodes: usize },
        DestroyRealm { realm_id: RealmId },
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub enum Host {
        Subscribe { nid: NodeIndex, realm_id: RealmId, realm_nid: NodeIndex },
    }
}

pub const NUM_REALMS: usize = 2;

pub mod events {
    use super::*;

    #[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Finite)]
    pub enum RealmRingBufferId {
        Net,
        Channel,
    }

    #[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
    pub struct RealmId(pub usize);

    impl Finite for RealmId {
        const CARDINALITY: usize = NUM_REALMS;

        fn to_nat(&self) -> usize {
            self.0
        }

        fn from_nat(n: usize) -> Self {
            Self(n)
        }
    }

    #[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
    pub struct SPI(pub usize);

    impl SPI {
        pub const START: usize = 32;
        pub const END: usize = 1020;
    }

    impl Finite for SPI {
        const CARDINALITY: usize = Self::END - Self::START;

        fn to_nat(&self) -> usize {
            self.0 + Self::START
        }

        fn from_nat(n: usize) -> Self {
            Self(n - Self::START)
        }
    }

    #[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Finite)]
    pub enum HostRingBufferIn {
        ResourceServer,
        SerialServer,
        Realm(RealmId, RealmRingBufferId),
    }

    #[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Finite)]
    pub enum HostRingBufferOut {
        Realm(RealmId, RealmRingBufferId),
    }

    #[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Finite)]
    pub enum HostIn {
        RealmEvent, // private
        SPI(SPI), // shared
        RingBuffer(HostRingBufferIn), // shared
    }

    #[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Finite)]
    pub enum HostOut {
        RingBuffer(HostRingBufferOut),
    }

    #[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Finite)]
    pub enum RealmRingBufferIn {
        Host(RealmRingBufferId),
        SerialServer,
    }

    #[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Finite)]
    pub enum RealmRingBufferOut {
        Host(RealmRingBufferId),
    }

    #[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Finite)]
    pub enum RealmIn {
        RingBuffer(RealmRingBufferIn),
    }

    #[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Finite)]
    pub enum RealmOut {
        RingBuffer(RealmRingBufferOut),
    }

    #[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Finite)]
    pub enum SerialServerRingBuffer {
        Host,
        Realm(RealmId),
    }

    #[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Finite)]
    pub enum SerialServerOut {
        RingBuffer(SerialServerRingBuffer),
    }

    #[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize, Finite)]
    pub enum ResourceServerOut {
        HostRingBuffer,
    }
}
