use icecap_std::prelude::*;

use crate::run::ClientId;

#[derive(Debug)]
pub enum Event {
    Interrupt,
    Timeout,
    Con(ClientId, RingBufferEvent),
}

#[derive(Debug)]
pub enum RingBufferEvent {
    Rx,
    Tx,
}

const EVENT_TYPE_INTERRUPT: Word = 0xCAFE;
const EVENT_TYPE_TIMEOUT: Word = 0x1EE8;
const EVENT_TYPE_CON: Word = 0x1EE9;

const EVENT_RX: Word = 1;
const EVENT_TX: Word = 2;

const ICECAP_RING_BUFFER_R_BADGE: Badge = 0x1;
const ICECAP_RING_BUFFER_W_BADGE: Badge = 0x2;

impl Event {

    pub fn get(info: MessageInfo) -> Self {
        match info.label() {
            EVENT_TYPE_INTERRUPT => {
                Self::Interrupt
            }
            EVENT_TYPE_TIMEOUT => {
                Self::Timeout
            }
            EVENT_TYPE_CON => {
                let client_id = MR_0.get() as ClientId;
                let ev = match MR_1.get() {
                    EVENT_RX => RingBufferEvent::Rx,
                    EVENT_TX => RingBufferEvent::Tx,
                    _ => panic!(),
                };
                Self::Con(client_id, ev)
            }
            _ => {
                panic!()
            }
        }
    }

    pub fn send(self, ep: &Endpoint) {
        match self {
            Self::Interrupt => {
                ep.call(MessageInfo::new(EVENT_TYPE_INTERRUPT, 0, 0, 0));
            }
            Self::Timeout => {
                ep.call(MessageInfo::new(EVENT_TYPE_TIMEOUT, 0, 0, 0));
            }
            Self::Con(client_id, ev) => {
                MR_0.set(client_id as Word);
                MR_1.set(match ev {
                    RingBufferEvent::Rx => EVENT_RX,
                    RingBufferEvent::Tx => EVENT_TX,
                });
                ep.call(MessageInfo::new(EVENT_TYPE_CON, 0, 0, 2));
            }
        }
    }

    pub fn for_badge<F: Fn(RingBufferEvent)>(badge: u64, f: F) {
        if badge & ICECAP_RING_BUFFER_W_BADGE != 0 {
            f(RingBufferEvent::Rx)
        }
        if badge & ICECAP_RING_BUFFER_R_BADGE != 0 {
            f(RingBufferEvent::Tx)
        }
    }

}
