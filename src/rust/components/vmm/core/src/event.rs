use core::convert::TryFrom;

use icecap_sel4::prelude::*;

#[derive(Debug)]
pub enum Event {
    Timeout,
    IRQ(usize),
}

#[derive(Debug)]
pub enum RingBufferEvent {
    Rx,
    Tx,
}

const EVENT_TYPE_TIMER: Word = 0x1EE8;
const EVENT_TYPE_IRQ: Word = 0xCAFE;

const ICECAP_RING_BUFFER_R_BADGE: Badge = 0x1;
const ICECAP_RING_BUFFER_W_BADGE: Badge = 0x2;

impl Event {

    pub fn get(info: MessageInfo) -> Self {
        match info.label() {
            EVENT_TYPE_TIMER => {
                Self::Timeout
            }
            EVENT_TYPE_IRQ => {
                let irq = MR_0.get();
                Self::IRQ(usize::try_from(irq).unwrap())
            }
            _ => {
                panic!()
            }
        }
    }

    pub fn send(self, ep: Endpoint) {
        match self {
            Self::Timeout => {
                ep.send(MessageInfo::new(EVENT_TYPE_TIMER, 0, 0, 0));
            }
            Self::IRQ(irq) => {
                MR_0.set(u64::try_from(irq).unwrap());
                ep.send(MessageInfo::new(EVENT_TYPE_IRQ, 0, 0, 1));
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
