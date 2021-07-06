#![no_std]
#![allow(unused_imports)]

extern crate alloc;

use alloc::vec::Vec;
use alloc::collections::BTreeMap;
use serde::{Serialize, Deserialize};
use icecap_config::*;
use icecap_event_server_types::*;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub lock: Notification,

    pub endpoints: Vec<Endpoint>,
    pub secondary_threads: Vec<Thread>,

    pub badges: Badges,

    pub host_notifications: Vec<Notification>,
    pub realm_notifications: Vec<Vec<Notification>>,
    pub resource_server_subscriptions: Vec<Notification>,

    pub irqs: BTreeMap<usize, (IRQHandler, Vec<Notification>)>,
    pub irq_threads: Vec<IRQThreadConfig>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Badges {
    pub client_badges: Vec<ClientId>,
    pub resource_server_badge: Badge,
    pub host_badge: Badge,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IRQThreadConfig {
    pub thread: Thread,
    pub notification: Notification,
    pub irqs: Vec<usize>, // per bit
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ClientId {
    ResourceServer,
    SerialServer,
    Host,
    Realm(RealmId),
}
