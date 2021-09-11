use core::{
    cell::RefCell,
};
use alloc::{
    sync::Arc,
};

use icecap_std::prelude::*;
use finite_set::Finite;

use super::*;

impl EventServer {

    pub fn create_realm(&mut self, rid: RealmId, num_nodes: usize) -> Fallible<()> {
        assert!(!self.realms.contains_key(&rid));
        let inactive = self.inactive_realms.get(&rid).unwrap();
        let client = inactive.create_client(num_nodes)?;
        self.realms.insert(rid, client);
        Ok(())
    }

    pub fn destroy_realm(&mut self, rid: RealmId) -> Fallible<()> {
        assert!(self.realms.remove(&rid).is_some());
        let inactive = self.inactive_realms.get(&rid).unwrap();
        inactive.destroy();
        Ok(())
    }

    pub fn host_subscribe(&mut self, nid: NodeIndex, rid: RealmId, realm_nid: NodeIndex) -> Fallible<()> {
        let in_space = &mut self.realms.get_mut(&rid).unwrap().in_spaces[realm_nid];
        let slot: SubscriptionSlot = in_space.borrow().subscription_slot.clone();
        let old = slot.replace(Some(self.host_subscriptions[nid].subscriber.clone()));
        assert!(old.is_none());
        assert!(self.host_subscriptions[nid].slot.is_none());
        self.host_subscriptions[nid].slot = Some(slot.clone());
        // in_space.borrow_mut().notify_if_necessary() // HACK
        Ok(())
    }

    pub fn resource_server_subscribe(&mut self, nid: NodeIndex, host_nid: NodeIndex) -> Fallible<()> {
        let in_space = &mut self.host.in_spaces[host_nid];
        let slot: SubscriptionSlot = in_space.borrow().subscription_slot.clone();
        let old = slot.replace(Some(self.resource_server_subscriptions[nid].subscriber.clone()));
        assert!(old.is_none());
        assert!(self.resource_server_subscriptions[nid].slot.is_none());
        self.resource_server_subscriptions[nid].slot = Some(slot.clone());
        // in_space.borrow_mut().notify_if_necessary() // HACK
        Ok(())
    }

    pub fn resource_server_unsubscribe(&mut self, nid: NodeIndex, host_nid: NodeIndex) -> Fallible<()> {
        let in_space = &mut self.host.in_spaces[host_nid];
        let slot: SubscriptionSlot = in_space.borrow().subscription_slot.clone();
        let old = slot.replace(None);
        self.resource_server_subscriptions[nid].slot = None;
        Ok(())
    }
}

impl Client {

    pub fn sev(&mut self, nid: NodeIndex) -> Fallible<()> {
        // self.in_spaces[nid].borrow_mut().notify_subscriber()
        panic!()
    }

    pub fn signal(&mut self, index: OutIndex) -> Fallible<()> {
        self.out_space[index].borrow().signal()
    }

    pub fn poll(&mut self, nid: NodeIndex) -> Fallible<Option<InIndex>> {
        panic!()
    }

    pub fn end(&mut self, nid: NodeIndex, index: InIndex) -> Fallible<()> {
        self.in_spaces[nid].borrow_mut().end(index)
    }

    pub fn configure(&mut self, nid: NodeIndex, index: InIndex, action: ConfigureAction) -> Fallible<()> {
        self.in_spaces[nid].borrow_mut().configure(index, action)
    }

    pub fn move_(&mut self, src_nid: NodeIndex, src_index: InIndex, dst_nid: NodeIndex, dst_index: InIndex) -> Fallible<()> {
        if (src_nid, src_index) != (dst_nid, dst_index) {
            let mut tmp = None;
            core::mem::swap(
                &mut tmp,
                &mut self.in_spaces[src_nid].borrow_mut().entries[src_index],
            );
            core::mem::swap(
                &mut tmp,
                &mut self.in_spaces[dst_nid].borrow_mut().entries[dst_index],
            );
            core::mem::swap(
                &mut tmp,
                &mut self.in_spaces[src_nid].borrow_mut().entries[src_index],
            );
            if let Some(entry) = self.in_spaces[dst_nid].borrow_mut().entries[dst_index].as_mut() {
                entry.event.borrow_mut().target = Some(EventTarget {
                    in_space: self.in_spaces[dst_nid].clone(),
                    index: dst_index,
                });
                if let Some(irq) = entry.event.borrow().irq.as_ref() {
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

    pub fn connect(event: &Arc<RefCell<Self>>, in_space: &Arc<RefCell<InSpace>>, in_index: usize) {
        assert!(in_space.borrow().entries[in_index].is_none());
        assert!(event.borrow().target.is_none());
        in_space.borrow_mut().entries[in_index] = Some(InSpaceEntry {
            event: event.clone(),
            // enabled: false,
            enabled: true, // TODO HACK
        });
        event.borrow_mut().target = Some(EventTarget {
            in_space: in_space.clone(),
            index: in_index,
        });
    }

    pub fn disconnect(&mut self) {
        self.target = None;
    }
}

impl InSpace {

    pub fn signal(&mut self, index: InIndex) -> Fallible<()> {
        let entry = self.entries[index].as_mut().unwrap();
        let bit_lot_index = index / 64;
        let bit_lot_bit = index % 64;
        // debug_println!("ix {}, addr 0x{:x}", index, self.notification.bitfield + bit_lot_index);
        let bit_lot = unsafe {
            &*((self.notification.bitfield + 8 * bit_lot_index) as *const core::sync::atomic::AtomicU64)
        };
        let old = bit_lot.fetch_or(1 << bit_lot_bit, core::sync::atomic::Ordering::SeqCst);
        if old & (1 << bit_lot_bit) == 0 {
            self.notification.nfn[bit_lot_index].signal();
            self.notify_subscriber()?;
        }
        Ok(())
    }

    // NOTE: internally end after moving to be safe
    pub fn end(&mut self, index: InIndex) -> Fallible<()> {
        let entry = self.entries[index].as_mut().unwrap();
        if let Some(irq) = &entry.event.borrow().irq {
            irq.handler.ack()?;
        } else {
            panic!()
        }
        Ok(())
    }

    pub fn configure(&mut self, index: InIndex, action: ConfigureAction) -> Fallible<()> {
        let entry = self.entries[index].as_mut().unwrap();
        match action {
            ConfigureAction::SetPriority(priority) => {
                panic!("prio");
            }
            ConfigureAction::SetEnabled(enabled) => {
                // TODO if backed by IRQ, unbind IRQ notification
                entry.enabled = enabled;
            }
        }
        // self.notify_if_necessary() // TODO
        Ok(())
    }

    pub fn notify_subscriber(&self) -> Fallible<()> {
        if let Some(subscriber) = self.subscription_slot.replace(None) {
            subscriber.signal()?;
        }
        Ok(())
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

        let client = Client {
            out_space: self.out_space.clone(),
            in_spaces: (0..num_nodes).map(|nid| {
                Arc::new(RefCell::new(InSpace {
                    notification: self.in_notifications[nid].clone(),
                    subscription_slot: Arc::new(RefCell::new(None)),
                    entries: (0..events::RealmIn::CARDINALITY).map(|_| None).collect(),
                }))
            }).collect()
        };

        for (in_index, entry) in self.in_entries.iter().enumerate() {
            if let Some(event) = entry {
                Event::connect(event, &client.in_spaces[0], in_index)
            }
        }

        Ok(client)
    }

    pub fn destroy(&self) {
        for entry in &self.in_entries {
            if let Some(event) = entry {
                event.borrow_mut().disconnect()
            }
        }
    }
}

///

impl IRQThread {

    pub fn run(&self) -> Fallible<()> {
        loop {
            let badge = self.notification.wait();
            let server = self.server.lock();
            for i in biterate(badge) {
                let irq = self.irqs[i as usize];
                server.irq_events[&irq].borrow().signal()?;
            }
        }
    }
}
