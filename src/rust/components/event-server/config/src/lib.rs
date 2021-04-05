#![no_std]
#![allow(unused_imports)]

extern crate alloc;

use alloc::vec::Vec;
use serde::{Serialize, Deserialize};
use icecap_config::*;
use icecap_event_server_types::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    badges: Vec<ClientId>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ClientId {
    ResourceServer,
    SerialServer,
    Host,
    Realm(RealmId),
}
