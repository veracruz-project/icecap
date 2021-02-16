#![allow(dead_code)]
#![allow(unused_variables)]
#![allow(unused_imports)]

use core::cmp::min;
use alloc::collections::VecDeque;
use alloc::vec::Vec;
use byteorder::{ByteOrder, LittleEndian};
use crate::ring_buffer::PacketRingBuffer;

pub const DEFAULT_RING_BUFFER_SIZE: usize = 0x100000;

pub struct NetDriver {
    rb: PacketRingBuffer,
    q: VecDeque<Vec<u8>>,
}

impl NetDriver {

    pub fn new(rb: PacketRingBuffer) -> Self {
        Self {
            rb,
            q: VecDeque::new(),
        }
    }

    pub fn flush_tx(&mut self) -> bool {
        let mut notify = false;
        loop {
            match self.q.get(0) {
                None => break,
                Some(buf) => {
                    // TODO split and send partial
                    if !self.rb.write(buf) {
                        break
                    }
                    self.q.pop_front();
                    notify = true;
                },
            }
        }
        notify
    }

    pub fn rx_callback(&self) {
    }

    pub fn tx_callback(&mut self) -> bool {
        let notify = self.flush_tx();
        if notify {
            self.rb.notify_write();
        }
        notify
    }

    pub fn poll(&self) -> Option<usize> {
        self.rb.poll()
    }

    pub fn rx(&mut self) -> Option<Vec<u8>> {
        let r = self.rb.read();
        if r.is_some() {
            self.rb.notify_read();
        }
        r
    }

    pub fn tx(&mut self, buf: &[u8]) -> bool {
        let mut notify = self.flush_tx();
        if self.rb.write(buf) {
            notify = true;
        } else {
            self.q.push_back(buf.to_vec());
        }
        if notify {
            self.rb.notify_write();
        }
        notify
    }


    pub fn packet_ring_buffer(&self) -> &PacketRingBuffer {
        &self.rb
    }

}
