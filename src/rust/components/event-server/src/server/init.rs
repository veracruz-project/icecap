use core::{
    cell::RefCell,
};
use alloc::{
    vec::Vec,
    collections::BTreeMap,
    rc::Rc,
};

use finite_set::Finite;
use biterate::biterate;

use icecap_std::{
    prelude::*,
    sync::Mutex,
};

use icecap_event_server_types::*;

use super::*;

pub struct EventServerConfig {
    pub host_notifications: Vec<Notification>,
    pub realm_notifications: Vec<Vec<Notification>>,
    pub resource_server_subscriptions: Vec<Notification>,
    pub irqs: BTreeMap<usize, (IRQHandler, Vec<Notification>)>,
}

fn mk_out_space(n: usize) -> OutSpace {
    (0..n).map(|_| Arc::new(RefCell::new(Event {
        target: None,
    }))).collect()
}

// fn mk_client(num_nodes: usize, )

impl EventServerConfig {

    pub fn realize(&self) -> (EventServer, BTreeMap<usize, usize>) { // irq -> irq_events index

        let resource_server_out = mk_out_space(events::ResourceServerOut::CARDINALITY);
        let serial_server_out = mk_out_space(events::SerialServerOut::CARDINALITY);
        let host_out = mk_out_space(events::HostOut::CARDINALITY);

        let realm_out: Vec<OutSpace> = (0..NUM_REALMS).map(|_| mk_out_space(events::RealmOut::CARDINALITY)).collect();

        let irq_event_map = todo!();

        let resource_server_in: Vec<Option<InSpaceEntry>> = vec![];
        let serial_server_in: Vec<Option<InSpaceEntry>> = vec![];
        let host_in: Vec<Option<InSpaceEntry>> = vec![];

        let server = EventServer {
            resource_server: todo!(),
            serial_server: todo!(),
            host: todo!(),
            realms: todo!(),
            inactive_realms: todo!(),

            resource_server_subscriptions: self.resource_server_subscriptions.iter().map(|notification| {
                SubscriptionEntry {
                    subscriber: Subscriber::Notification(*notification),
                    slot: None
                }
            }).collect(),

            host_subscriptions: todo!(),

            irq_events: todo!(),
        };

        (server, irq_event_map)
    }
}
