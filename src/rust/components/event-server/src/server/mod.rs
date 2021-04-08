use core::{
    cell::RefCell,
};
use alloc::{
    vec::Vec,
    collections::BTreeMap,
    sync::Arc,
};

use biterate::biterate;

use icecap_std::{
    prelude::*,
    sync::Mutex,
};

use icecap_event_server_types::*;

mod impls;
mod init;

pub use init::EventServerConfig;

pub const NUM_NODES: usize = 3;

// HACK
unsafe impl Send for EventServer {}

pub struct EventServer {
    pub resource_server: Client,
    pub serial_server: Client,
    pub host: Client,
    pub realms: BTreeMap<RealmId, Client>,
    pub inactive_realms: BTreeMap<RealmId, InactiveRealm>,

    pub resource_server_subscriptions: Vec<SubscriptionEntry>,
    pub host_subscriptions: Vec<SubscriptionEntry>,

    pub irq_events: Vec<Arc<RefCell<Event>>>,
}

pub struct Client {
    pub out_space: OutSpace,
    pub in_spaces: Vec<Arc<RefCell<InSpace>>>,
}

type OutSpace = Vec<Arc<RefCell<Event>>>;

pub struct InSpace {
    pub entries: Vec<Option<InSpaceEntry>>,
    pub notification: Notification,
    pub subscription_slot: SubscriptionSlot,
}

pub struct InSpaceEntry {
    pub event: Arc<RefCell<Event>>,
    pub irq: Option<EventIRQ>,
    pub enabled: bool,
    pub priority: usize,
    pub active: bool,
    pub pending: bool,
}

pub struct Event {
    pub target: Option<EventTarget>,
}

pub struct EventTarget {
    pub in_space: Arc<RefCell<InSpace>>,
    pub index: usize,
}

pub struct EventIRQ {
    pub handler: IRQHandler,
    pub notifications: Vec<Notification>,
}

#[derive(Clone)]
pub enum Subscriber {
    Event(Arc<RefCell<Event>>),
    Notification(Notification),
}

type SubscriptionSlot = Arc<RefCell<Option<Subscriber>>>;

pub struct SubscriptionEntry {
    pub subscriber: Subscriber,
    pub slot: Option<SubscriptionSlot>,
}

pub struct InactiveRealm {
    pub out_space: OutSpace,
    pub in_notifications: Vec<Notification>,
    pub in_entries: Vec<Option<Arc<RefCell<Event>>>>,
}

pub struct IRQThread {
    pub notification: Notification,
    pub events: Vec<usize>,
    pub server: Arc<Mutex<EventServer>>,
}
