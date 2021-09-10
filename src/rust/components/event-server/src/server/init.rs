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
use icecap_event_server_config::VMMNode;

use super::*;

pub struct EventServerConfig {
    pub host_notifications: Vec<VMMNode>,
    pub realm_notifications: Vec<Vec<VMMNode>>,
    pub resource_server_subscriptions: Vec<Notification>,
    pub irqs: BTreeMap<usize, (IRQHandler, Vec<Notification>)>,
}

const PRIMARY_HOST_NODE: usize = 0;

fn mk_out_space(n: usize) -> OutSpace {
    (0..n).map(|_| Arc::new(RefCell::new(Event {
        target: None,
        irq: None,
    }))).collect()
}

impl EventServerConfig {

    pub fn realize(&self) -> EventServer {

        let resource_server = Client {
            out_space: mk_out_space(events::ResourceServerOut::CARDINALITY),
            in_spaces: vec![],
        };

        let serial_server = Client {
            out_space: mk_out_space(events::SerialServerOut::CARDINALITY),
            in_spaces: vec![],
        };

        let host = Client {
            out_space: mk_out_space(events::HostOut::CARDINALITY),
            in_spaces: (0..NUM_NODES).map(|node_index| {
                Arc::new(RefCell::new(InSpace {
                    entries: (0..events::HostIn::CARDINALITY).map(|_| None).collect(),
                    notification: self.host_notifications[node_index].clone(),
                    subscription_slot: Arc::new(RefCell::new(None)),
                }))
            }).collect(),
        };

        let mut inactive_realms: BTreeMap<usize, InactiveRealm> = (0..NUM_REALMS).map(|realm_id|
            (
                realm_id,
                InactiveRealm {
                    out_space: mk_out_space(events::RealmOut::CARDINALITY),
                    in_notifications: self.realm_notifications[realm_id].clone(),
                    in_entries: (0..events::RealmIn::CARDINALITY).map(|_| None).collect(),
                },
            )
        ).collect();

        for (out_index, event) in resource_server.out_space.iter().enumerate() {
            match events::ResourceServerOut::from_nat(out_index) {
                events::ResourceServerOut::HostRingBuffer =>
                    Event::connect(
                        event,
                        &host.in_spaces[PRIMARY_HOST_NODE],
                        events::HostIn::RingBuffer(events::HostRingBufferIn::ResourceServer).to_nat(),
                    ),
            }
        }

        for (out_index, event) in serial_server.out_space.iter().enumerate() {
            match events::SerialServerOut::from_nat(out_index) {
                events::SerialServerOut::RingBuffer(ring_buffer) => match ring_buffer {
                    events::SerialServerRingBuffer::Host =>
                        Event::connect(
                            event,
                            &host.in_spaces[PRIMARY_HOST_NODE],
                            events::HostIn::RingBuffer(events::HostRingBufferIn::SerialServer).to_nat(),
                        ),
                    events::SerialServerRingBuffer::Realm(realm_id) => {
                        inactive_realms.get_mut(&realm_id.0).unwrap().in_entries[events::RealmIn::RingBuffer(events::RealmRingBufferIn::SerialServer).to_nat()] = Some(event.clone());
                    }
                }
            }
        }

        for (out_index, event) in host.out_space.iter().enumerate() {
            match events::HostOut::from_nat(out_index) {
                events::HostOut::RingBuffer(ring_buffer) => match ring_buffer {
                    events::HostRingBufferOut::Realm(realm_id) => {
                        inactive_realms.get_mut(&realm_id.0).unwrap().in_entries[events::RealmIn::RingBuffer(events::RealmRingBufferIn::Host).to_nat()] = Some(event.clone());
                    }
                }
            }
        }

        for (realm_id, inactive_realm) in inactive_realms.iter() {
            for (out_index, event) in inactive_realm.out_space.iter().enumerate() {
                match events::RealmOut::from_nat(out_index) {
                    events::RealmOut::RingBuffer(ring_buffer) => match ring_buffer {
                        events::RealmRingBufferOut::Host =>
                            Event::connect(
                                event,
                                &host.in_spaces[PRIMARY_HOST_NODE],
                                events::HostIn::RingBuffer(events::HostRingBufferIn::Realm(events::RealmId::from_nat(*realm_id))).to_nat(),
                            ),
                    }
                }
            }
        }

        let resource_server_subscriptions = self.resource_server_subscriptions.iter().map(|notification| {
            SubscriptionEntry {
                subscriber: Subscriber::Notification(*notification),
                slot: None
            }
        }).collect();

        let host_subscriptions = (0..NUM_NODES).map(|node_index| {
            let event = Arc::new(RefCell::new(Event {
                target: None,
                irq: None,
            }));
            Event::connect(&event, &host.in_spaces[node_index], events::HostIn::RealmEvent.to_nat());
            SubscriptionEntry {
                subscriber: Subscriber::Event(event),
                slot: None
            }
        }).collect();

        let irq_events = self.irqs.iter().map(|(irq, (handler, notifications))| {
            let event = Arc::new(RefCell::new(Event {
                target: None,
                irq: Some(EventIRQ {
                    handler: handler.clone(),
                    notifications: notifications.clone(),
                }),
            }));
            Event::connect(
                &event,
                &host.in_spaces[PRIMARY_HOST_NODE],
                events::HostIn::SPI(events::SPI(*irq)).to_nat(),
            );
            (*irq, event)
        }).collect();

        EventServer {
            resource_server,
            serial_server,
            host,
            realms: BTreeMap::new(),
            inactive_realms,
            resource_server_subscriptions,
            host_subscriptions,
            irq_events,
        }
    }
}
