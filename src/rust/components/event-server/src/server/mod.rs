use core::{
    cell::RefCell,
};
use alloc::{
    vec::Vec,
    collections::BTreeMap,
    rc::Rc,
};

use biterate::biterate;

use icecap_std::{
    prelude::*,
    sync::Mutex,
};

use icecap_event_server_types::*;

mod impls;

pub struct EventServer {
    pub resource_server: Client,
    pub serial_server: Client,
    pub host: Client,
    pub realms: BTreeMap<RealmId, Client>,
    pub inactive_realms: BTreeMap<RealmId, InactiveRealm>,

    pub resource_server_subscriptions: Vec<SubscriptionEntry>,
    pub host_subscriptions: Vec<SubscriptionEntry>,

    pub irq_events: Vec<Rc<RefCell<Event>>>,
}

pub struct Client {
    pub out_space: OutSpace,
    pub in_spaces: Vec<InSpace>,
}

type OutSpace = Vec<Rc<RefCell<Event>>>;

pub struct InSpace {
    pub entries: Vec<Option<InSpaceEntry>>,
    pub notification: Notification,
    pub subscription_slot: SubscriptionSlot,
}

pub struct InSpaceEntry {
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
    pub in_space: Rc<RefCell<InSpace>>,
    pub index: usize,
}

pub struct EventIRQ {
    pub handler: IRQHandler,
    pub notifications: Vec<Notification>,
}

#[derive(Clone)]
pub enum Subscriber {
    Event(Rc<RefCell<Event>>),
    Notification(Notification),
}

type SubscriptionSlot = Rc<RefCell<Option<Subscriber>>>;

pub struct SubscriptionEntry {
    pub subscriber: Subscriber,
    pub slot: Option<SubscriptionSlot>,
}

pub struct InactiveRealm {
    pub out_space: OutSpace,
    pub in_notifications: Vec<Notification>,
    pub in_entries: Vec<Option<Rc<RefCell<Event>>>>,
}

pub enum ConfigureAction {
    SetEnabled(bool),
    SetPriority(usize),
}

pub struct IRQThread {
    pub notification: Notification,
    pub events: Vec<Option<usize>>,
    pub server: Mutex<EventServer>,
}
