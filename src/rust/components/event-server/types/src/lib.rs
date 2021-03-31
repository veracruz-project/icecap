#![no_std]
#![allow(unused_imports)]

use serde::{Serialize, Deserialize};

use finite_set::*;
use icecap_rpc::*;

pub type RealmId = usize;
pub type NodeIndex = usize;
pub type OutIndex = usize;
pub type InIndex = usize;

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
        End { nid: NodeIndex, index: OutIndex },
        Configure { nid: NodeIndex, index: InIndex, action: ConfigureAction },
        Move { src_nid: NodeIndex, src_index: InIndex, dst_nid: NodeIndex, dst_index: InIndex },
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub enum ResourceServer {
        Subscribe { nid: NodeIndex, host_nid: NodeIndex },
        CreateRealm { realm_id: RealmId, num_nodes: usize },
        DestroyRealm { realm_id: RealmId },
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub enum Host {
        Subscribe { nid: NodeIndex, realm_id: RealmId, realm_nid: NodeIndex },
    }
}

pub const NUM_REALMS: usize = 10;

pub mod events {
    use super::*;

    #[derive(Clone, Debug, Eq, PartialEq, Finite)]
    pub enum RealmRingBufferId {
        Net,
        Con,
        Channel,
    }

    #[derive(Clone, Debug, Eq, PartialEq, Finite)]
    pub enum RingBufferSide {
        Read,
        Write,
    }

    #[derive(Clone, Debug, Eq, PartialEq)]
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

    #[derive(Clone, Debug, Eq, PartialEq)]
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

    #[derive(Clone, Debug, Eq, PartialEq, Finite)]
    pub enum HostRingBuffer {
        ResourceServer,
        SerialServer,
        Realm(RealmId),
    }

    #[derive(Debug, Eq, PartialEq, Finite)]
    pub enum HostIn {
        RealmEvent, // private
        SPI(SPI), // shared
        RingBuffer(HostRingBuffer, RingBufferSide), // shared
    }

    #[derive(Clone, Debug, Eq, PartialEq, Finite)]
    pub enum HostOut {
        RingBuffer(HostRingBuffer, RingBufferSide),
    }

    #[derive(Clone, Debug, Eq, PartialEq, Finite)]
    pub enum RealmRingBuffer {
        Host,
        SerialServer,
    }

    #[derive(Clone, Debug, Eq, PartialEq, Finite)]
    pub enum RealmIn {
        RingBuffer(RealmRingBuffer, RingBufferSide),
    }

    #[derive(Clone, Debug, Eq, PartialEq, Finite)]
    pub enum RealmOut {
        RingBuffer(RealmRingBuffer, RingBufferSide),
    }

    #[derive(Clone, Debug, Eq, PartialEq, Finite)]
    pub enum SerialServerRingBuffer {
        Host,
        Realm(RealmId),
    }

    #[derive(Clone, Debug, Eq, PartialEq, Finite)]
    pub enum SerialServerOut {
        RingBuffer(SerialServerRingBuffer, RingBufferSide),
    }

    #[derive(Clone, Debug, Eq, PartialEq, Finite)]
    pub enum ResourceServerOut {
        HostRingBuffer(RingBufferSide),
    }
}
