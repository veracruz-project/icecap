#![no_std]
#![allow(unused_imports)]

use icecap_rpc::*;

pub type RealmId = usize;
pub type NodeIndex = usize;
pub type OutIndex = usize;
pub type InIndex = usize;

pub mod calls {
    use super::*;

    pub enum Client {
        SEV { nid: NodeIndex },
    }
}