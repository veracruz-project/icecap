#![no_std]

use serde::{Serialize, Deserialize};

use finite_set::*;

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
