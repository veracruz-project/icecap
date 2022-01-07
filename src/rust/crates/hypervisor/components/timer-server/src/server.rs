use alloc::collections::{BTreeMap, BTreeSet};
use core::cmp::Ordering;
use core::result;

use icecap_drivers::timer::TimerDevice;
use icecap_std::prelude::*;

pub type Error = ();
pub type ClientId = usize;
pub type TimerId = i64;
pub type Nanosecond = i64;

type Tick = i64;

const NS_IN_S: i64 = 1000000000;

#[derive(Debug, Eq, PartialEq)]
struct Period {
    // TODO Depending on tick to ns conversion, this could drift. Is that ok? Which clients will tolerate that?
    period: Tick,
}

#[derive(Debug, Eq)]
struct Timer {
    client: ClientId,
    timer: TimerId,
    compare: Tick,
    period: Option<Period>,
}

impl Ord for Timer {
    fn cmp(&self, other: &Self) -> Ordering {
        self.compare.cmp(&other.compare)
    }
}

impl PartialOrd for Timer {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        self.compare.partial_cmp(&other.compare)
    }
}

impl PartialEq for Timer {
    fn eq(&self, other: &Self) -> bool {
        self.compare.eq(&other.compare)
    }
}

#[derive(Debug)]
struct Timers(Vec<Timer>);

impl Timers {
    fn new() -> Self {
        Timers(vec![])
    }

    fn insert(&mut self, timer: Timer) {
        let pos = self.0.binary_search(&timer).unwrap_or_else(|e| e);
        self.0.insert(pos, timer);
    }

    fn compare(&self) -> Option<Tick> {
        if self.0.len() == 0 {
            None
        } else {
            Some(self.0[0].compare)
        }
    }
}

type Completed = BTreeMap<ClientId, BTreeSet<TimerId>>;

pub struct Server<D: TimerDevice> {
    clients: Vec<Notification>,
    timers_per_client: TimerId,
    completed: Completed,
    outstanding: Timers,
    device: D,
    freq: u32,
}

impl<D: TimerDevice> Server<D> {
    pub fn new(clients: Vec<Notification>, timers_per_client: TimerId, device: D) -> Self {
        assert!(clients.len() <= 64);
        assert!(timers_per_client <= 64);
        let freq = device.get_freq();
        let mut server = Self {
            clients,
            timers_per_client,
            completed: BTreeMap::new(),
            outstanding: Timers::new(),
            device,
            freq,
        };
        for client in 0..server.clients.len() {
            server.completed.insert(client, BTreeSet::new());
        }
        server
    }

    fn ns_to_tick(&self, ns: Nanosecond) -> Tick {
        (((ns as i128) * (self.freq as i128)) / (NS_IN_S as i128)) as Tick
    }

    fn tick_to_ns(&self, tick: Tick) -> Nanosecond {
        (((tick as i128) * (NS_IN_S as i128)) / (self.freq as i128)) as Nanosecond
    }

    fn signal(&self, client: ClientId) {
        self.clients[client].signal();
    }

    fn now_tick(&self) -> Tick {
        self.device.get_count() as i64
    }

    fn now_ns(&self) -> Nanosecond {
        self.tick_to_ns(self.now_tick())
    }

    pub fn handle_interrupt(&mut self) {
        self.device.clear_interrupt();
        self.update(self.now_tick());
    }

    fn update_timers(&mut self, count: Tick) {
        while self.outstanding.0.len() > 0 && self.outstanding.0[0].compare <= count {
            let mut timer = self.outstanding.0.remove(0);
            let client = timer.client;
            self.completed
                .get_mut(&timer.client)
                .unwrap()
                .insert(timer.timer);
            if let Some(period) = &timer.period {
                timer.compare += period.period;
                self.outstanding.insert(timer);
            }
            self.signal(client);
        }
    }

    fn update_device(&mut self) {
        if let Some(t) = self.outstanding.compare() {
            if self.device.set_compare(t as u64) {
                self.device.set_enable(true);
            } else {
                self.update(self.now_tick());
            }
        } else {
            self.device.set_enable(false);
        }
    }

    fn update(&mut self, count: Tick) {
        self.update_timers(count);
        self.update_device();
    }

    fn guard_tid(&self, tid: TimerId) -> result::Result<(), Error> {
        if tid > self.timers_per_client {
            Err(())
        } else {
            Ok(())
        }
    }

    fn set_timer(&mut self, timer: Timer) {
        self.remove_timer(timer.client, timer.timer);
        self.outstanding.insert(timer);
    }

    fn remove_timer(&mut self, cid: ClientId, tid: TimerId) {
        for _ in self
            .outstanding
            .0
            .drain_filter(|timer| timer.client == cid && timer.timer == tid)
        {
            self.completed.get_mut(&cid).unwrap().remove(&tid);
        }
    }

    pub fn oneshot_relative(
        &mut self,
        cid: ClientId,
        tid: TimerId,
        ns: Nanosecond,
    ) -> result::Result<(), Error> {
        self.guard_tid(tid)?;
        let now = self.now_tick();
        self.set_timer(Timer {
            client: cid,
            timer: tid,
            compare: now + self.ns_to_tick(ns),
            period: None,
        });
        self.update(now);
        Ok(())
    }

    pub fn oneshot_absolute(
        &mut self,
        cid: ClientId,
        tid: TimerId,
        ns: Nanosecond,
    ) -> result::Result<(), Error> {
        self.guard_tid(tid)?;
        let now = self.now_tick();
        self.set_timer(Timer {
            client: cid,
            timer: tid,
            compare: self.ns_to_tick(ns),
            period: None,
        });
        self.update(now);
        Ok(())
    }

    pub fn periodic(
        &mut self,
        cid: ClientId,
        tid: TimerId,
        ns: Nanosecond,
    ) -> result::Result<(), Error> {
        self.guard_tid(tid)?;
        let now = self.now_tick();
        let period = self.ns_to_tick(ns);
        self.set_timer(Timer {
            client: cid,
            timer: tid,
            compare: now + period,
            period: Some(Period { period }),
        });
        self.update(now);
        Ok(())
    }

    pub fn stop(&mut self, cid: ClientId, tid: TimerId) -> result::Result<(), Error> {
        self.guard_tid(tid)?;
        self.remove_timer(cid, tid);
        Ok(())
    }

    pub fn completed(&mut self, cid: ClientId) -> Word {
        let mut mask = 0;
        let completed = self.completed.remove(&cid).unwrap();
        for tid in completed {
            mask |= 1 << tid;
        }
        self.completed.insert(cid, BTreeSet::new());
        mask
    }

    pub fn time(&mut self, _cid: ClientId) -> Nanosecond {
        self.now_ns()
    }
}
