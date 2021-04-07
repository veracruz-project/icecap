use core::{
    cell::RefCell,
};
use alloc::{
    vec::Vec,
    collections::BTreeMap,
    rc::Rc,
};

use icecap_std::prelude::*;

use super::*;

impl EventServer {

    pub fn create_realm(&mut self, rid: RealmId, num_nodes: usize) -> Fallible<()> {
        assert!(self.realms.contains_key(&rid));
        let inactive = self.inactive_realms.get(&rid).unwrap();
        let client = inactive.create_client(num_nodes)?;
        self.realms.insert(rid, client);
        Ok(())
    }

    pub fn destroy_realm(&mut self, rid: RealmId) -> Fallible<()> {
        assert!(self.realms.remove(&rid).is_some());
        Ok(())
    }

    pub fn host_subscribe(&mut self, nid: NodeIndex, rid: RealmId, realm_nid: NodeIndex) -> Fallible<()> {
        let in_space = &mut self.realms.get_mut(&rid).unwrap().in_spaces[realm_nid];
        let slot: SubscriptionSlot = in_space.subscription_slot.clone();
        let old = slot.replace(Some(self.host_subscriptions[nid].subscriber.clone()));
        assert!(old.is_none());
        assert!(self.host_subscriptions[nid].slot.is_none());
        self.host_subscriptions[nid].slot = Some(slot.clone());
        in_space.notify_if_necessary() // HACK
    }
}

impl Client {

    pub fn sev(&mut self, nid: NodeIndex) -> Fallible<()> {
        self.in_spaces[nid].notify_subscriber()
    }

    pub fn signal(&mut self, index: OutIndex) -> Fallible<()> {
        self.out_space[index].borrow().signal()
    }

    pub fn poll(&mut self, nid: NodeIndex) -> Fallible<Option<InIndex>> {
        self.in_spaces[nid].poll()
    }

    pub fn end(&mut self, nid: NodeIndex, index: InIndex) -> Fallible<()> {
        self.in_spaces[nid].end(index)
    }

    pub fn configure(&mut self, nid: NodeIndex, index: InIndex, action: ConfigureAction) -> Fallible<()> {
        self.in_spaces[nid].configure(index, action)
    }

    pub fn move_(&mut self, src_nid: NodeIndex, src_index: InIndex, dst_nid: NodeIndex, dst_index: InIndex) -> Fallible<()> {
        if (src_nid, src_index) != (dst_nid, dst_index) {
            let mut tmp = None;
            core::mem::swap(
                &mut tmp,
                &mut self.in_spaces[src_nid].entries[src_index],
            );
            core::mem::swap(
                &mut tmp,
                &mut self.in_spaces[dst_nid].entries[dst_index],
            );
            core::mem::swap(
                &mut tmp,
                &mut self.in_spaces[src_nid].entries[src_index],
            );
            if let Some(entry) = self.in_spaces[dst_nid].entries[dst_index].as_ref() {
                if let Some(irq) = entry.irq.as_ref() {
                    irq.handler.set_notification(irq.notifications[dst_index])?;
                }
            }
        }
        Ok(())
    }
}

impl Event {

    pub fn signal(&self) -> Fallible<()> {
        if let Some(target) = &self.target {
            target.in_space.borrow_mut().signal(target.index)?;
        }
        Ok(())
    }
}

impl InSpace {

    pub fn signal(&mut self, index: InIndex) -> Fallible<()> {
        let entry = self.entries[index].as_mut().unwrap();
        entry.pending = true;
        self.notify_if_necessary()
    }

    pub fn poll(&mut self) -> Fallible<Option<InIndex>> {
        for (i, entry) in (&mut self.entries).into_iter().enumerate() {
            if let Some(entry) = entry {
                if entry.enabled && entry.pending && !entry.active {
                    entry.pending = false;
                    entry.active = true;
                    return Ok(Some(i))
                }
            }
        }
        Ok(None)
    }

    // NOTE: internally end after moving to be safe
    pub fn end(&mut self, index: InIndex) -> Fallible<()> {
        let entry = self.entries[index].as_mut().unwrap();
        entry.active = false;
        if let Some(irq) = &entry.irq {
            irq.handler.ack()?;
        }
        self.notify_if_necessary()
    }

    pub fn configure(&mut self, index: InIndex, action: ConfigureAction) -> Fallible<()> {
        let entry = self.entries[index].as_mut().unwrap();
        match action {
            ConfigureAction::SetPriority(priority) => {
                entry.priority = priority;
            }
            ConfigureAction::SetEnabled(enabled) => {
                // TODO if backed by IRQ, unbind IRQ notification
                entry.enabled = enabled;
            }
        }
        self.notify_if_necessary()
    }
    
    pub fn notify_subscriber(&self) -> Fallible<()> {
        if let Some(subscriber) = self.subscription_slot.replace(None) {
            subscriber.signal()?;
        }
        Ok(())
    }

    // HACK
    pub fn notify_if_necessary(&mut self) -> Fallible<()> {
        for entry in &self.entries {
            if let Some(entry) = entry {
                if entry.enabled && entry.pending {
                    self.notify()?;
                    break;
                }
            }
        }
        Ok(())
    }

    pub fn notify(&self) -> Fallible<()> {
        self.notification.signal();
        self.notify_subscriber()
    }
}

impl Subscriber {

    pub fn signal(&self) -> Fallible<()> {
        match self {
            Self::Event(ev) => ev.borrow().signal()?,
            Self::Notification(nfn) => nfn.signal(),
        }
        Ok(())
    }
}

impl InactiveRealm {

    pub fn create_client(&self, num_nodes: usize) -> Fallible<Client> {
        assert!(num_nodes <= self.in_notifications.len());
        Ok(Client {
            out_space: self.out_space.clone(),
            in_spaces: (0..num_nodes).map(|nid| {
                InSpace {
                    notification: self.in_notifications[nid],
                    subscription_slot: Rc::new(RefCell::new(None)),
                    entries: self.out_space.iter().map(|event| {
                        if nid == 0 {
                            Some(InSpaceEntry {
                                irq: None,
                                enabled: true,
                                priority: 0,
                                active: false,
                                pending: false,
                            })
                        } else {
                            None
                        }
                    }).collect(),
                }
            }).collect(),
        })
    }
}

///

impl IRQThread {

    pub fn run(&self) -> Fallible<()> {
        loop {
            let badge = self.notification.wait();
            let server = self.server.lock();
            for i in biterate(badge) {
                if let Some(j) = self.events[i as usize] {
                    server.irq_events[j].borrow().signal()?;
                }
            }
        }
    }
}
