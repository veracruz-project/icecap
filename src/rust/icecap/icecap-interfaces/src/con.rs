use core::cmp::min;
use alloc::collections::VecDeque;
use alloc::vec::Vec;
use crate::ring_buffer::RingBuffer;

pub struct ConDriver {
    rb: RingBuffer,
    q: VecDeque<Vec<u8>>,
}

impl ConDriver {

    pub fn new(rb: RingBuffer) -> Self {
        Self {
            rb,
            q: VecDeque::new(),
        }
    }

    pub fn ring_buffer(&self) -> &RingBuffer {
        &self.rb
    }

    pub fn flush_tx(&mut self) -> bool {
        let mut notify = false;
        loop {
            match self.q.get(0) {
                None => break,
                Some(buf) => {
                    if self.rb.poll_write() < buf.len() {
                        // TODO split and send partial
                        break;
                    }
                    self.rb.write(buf.as_slice());
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

    pub fn poll(&self) -> usize {
        self.rb.poll_read()
    }

    pub fn rx_into(&mut self, buf: &mut [u8]) -> usize {
        let n_real = min(buf.len(), self.poll());
        if n_real > 0 {
            self.rb.read(&mut buf[0..n_real]);
            self.rb.notify_read();
        }
        n_real
    }

    pub fn rx(&mut self) -> Option<Vec<u8>> {
        let n = self.poll();
        if n > 0 {
            let mut buf = vec![0; n];
            self.rb.read(buf.as_mut_slice());
            self.rb.notify_read();
            return Some(buf)
        }
        None
    }

    pub fn tx(&mut self, buf: &[u8]) -> bool {
        let mut notify = self.flush_tx();

        // TODO split and send partial
        if self.rb.poll_write() < buf.len() {
            self.q.push_back(buf.to_vec());
        } else {
            self.rb.write(buf);
            notify = true;
        }

        if notify {
            self.rb.notify_write();
        }
        notify
    }

}
