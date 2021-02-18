use core::convert::TryFrom;

use icecap_sel4::prelude::*;

use crate::{
    gic::{IRQ, CPU},
};

#[derive(Debug)]
pub enum Event {
    SPI(IRQ),
    SGI(IRQ),
}

#[derive(Debug)]
pub enum RingBufferEvent {
    Rx,
    Tx,
}

const EVENT_TYPE_SPI: Word = 0xCAFE;
const EVENT_TYPE_SGI: Word = 0xFAFF;
const EVENT_TYPE_FWD_PPI: Word = 0xFACE;
const EVENT_TYPE_FWD_ACK: Word = 0xB0CE;

const ICECAP_RING_BUFFER_R_BADGE: Badge = 0x1;
const ICECAP_RING_BUFFER_W_BADGE: Badge = 0x2;

impl Event {

    pub fn get(info: MessageInfo) -> Self {
        match info.label() {
            EVENT_TYPE_SPI => {
                let irq = usize::try_from(MR_0.get()).unwrap();
                Self::SPI(irq)
            }
            EVENT_TYPE_SGI => {
                let irq = usize::try_from(MR_0.get()).unwrap();
                Self::SGI(irq)
            }
            _ => {
                panic!()
            }
        }
    }

    pub fn send(self, ep: Endpoint) {
        match self {
            Self::SPI(irq) => {
                MR_0.set(u64::try_from(irq).unwrap());
                ep.send(MessageInfo::new(EVENT_TYPE_SPI, 0, 0, 1));
            }
            Self::SGI(irq) => {
                MR_0.set(u64::try_from(irq).unwrap());
                ep.send(MessageInfo::new(EVENT_TYPE_SGI, 0, 0, 2));
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
