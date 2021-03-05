#![allow(dead_code)]
#![allow(unused_variables)]

use core::arch::aarch64::{__dsb, __dmb, SY};
use core::cmp::max;
use core::ops::Deref;
use core::ptr::{read_volatile, write_volatile};
use core::sync::atomic::{fence, Ordering};
use alloc::vec::Vec;
use byteorder::{ByteOrder, LittleEndian};
use register::{mmio::*, register_bitfields, register_structs};

use icecap_sel4::Notification;

register_bitfields! [
    u64,
    pub Status [
        NOTIFY_READ  OFFSET(1) NUMBITS(1) [],
        NOTIFY_WRITE OFFSET(0) NUMBITS(1) []
    ]
];

// TODO ReadOnly when possible
register_structs! {
    pub CtrlBlock {
        (0x000 => offset_r: ReadWrite<u64>),
        (0x008 => offset_w: ReadWrite<u64>),
        (0x010 => status: ReadWrite<u64, Status::Register>),
        (0x018 => @END),
    }
}

#[derive(Debug)]
pub struct Ctrl {
    pub base_addr: usize,
}

impl Ctrl {
    pub fn new(base_addr: usize) -> Self {
        Self {
            base_addr,
        }
    }
    fn ptr(&self) -> *const CtrlBlock {
        self.base_addr as *const _
    }
}

impl Deref for Ctrl {
    type Target = CtrlBlock;
    fn deref(&self) -> &Self::Target {
        unsafe { &*self.ptr() }
    }
}

fn dsb_sy() {
    unsafe {
        __dsb(SY)
    }
}

fn dmb_sy() {
    unsafe {
        __dmb(SY)
    }
}

fn acquire() {
    fence(Ordering::Acquire);
    // HACK
    dsb_sy();
    dmb_sy();
}

fn release() {
    fence(Ordering::Release);
    // HACK
    dsb_sy();
    dmb_sy();
}

#[derive(Debug)]
pub struct RingBufferSide<T> {
    pub size: usize,
    pub notification: Notification,
    pub ctrl: Ctrl,
    pub buf: T,
}

unsafe impl Send for RingBufferSide<*const u8> {}
unsafe impl Send for RingBufferSide<*mut u8> {}

impl<T> RingBufferSide<T> {
    pub fn new(size: usize, notification: Notification, ctrl_addr: usize, buf: T) -> Self {
        Self {
            size,
            notification,
            ctrl: Ctrl::new(ctrl_addr),
            buf: buf, // TODO
        }
    }
}

#[derive(Debug)]
pub struct RingBuffer {
    pub read: RingBufferSide<*const u8>,
    pub write: RingBufferSide<*mut u8>,
    private_offset_r: usize,
    private_offset_w: usize,
}

impl RingBuffer {

    pub fn new(read: RingBufferSide<*const u8>, write: RingBufferSide<*mut u8>) -> Self {
        Self {
            read,
            write,
            private_offset_r: 0,
            private_offset_w: 0,
        }
    }

    pub fn resume(read: RingBufferSide<*const u8>, write: RingBufferSide<*mut u8>) -> Self {
        let private_offset_r = write.ctrl.offset_r.get() as usize;
        let private_offset_w = write.ctrl.offset_w.get() as usize;
        Self {
            read,
            write,
            private_offset_r,
            private_offset_w,
        }
    }

    pub fn poll_read(&self) -> usize {
        acquire();
        let offset_r = self.private_offset_r;
        release();
        let offset_w = self.read.ctrl.offset_w.get() as usize;
        assert!(offset_r <= offset_w);
        assert!(offset_w - offset_r <= self.read.size);
        return offset_w - offset_r;
    }

    pub fn poll_write(&self) -> usize {
        acquire();
        let offset_r = self.read.ctrl.offset_r.get() as usize;
        release();
        let offset_w = self.private_offset_w;
        assert!(offset_r <= offset_w);
        assert!(offset_w - offset_r <= self.write.size);
        return max(0, self.write.size - (offset_w - offset_r) - 1);
    }

    pub fn read(&mut self, n: usize, buf: &mut [u8]) {
        self.peek(n, buf);
        self.skip(n);
    }

    pub fn skip(&mut self, n: usize) {
        acquire();
        assert!(n <= self.poll_read());
        self.private_offset_r += n;
        release();
    }

    pub fn peek(&self, n: usize, buf: &mut [u8]) {
        acquire();
        assert!(n <= self.poll_read());
        // TODO core::ptr::volatile_copy_nonoverlapping_memory
        for i in 0..n {
            let off = ((self.private_offset_r + i) % self.read.size) as isize;
            buf[i] = unsafe {
                read_volatile(self.read.buf.offset(off))
            }
        }
        release();
    }

    pub fn write(&mut self, buf: &[u8]) {
        acquire();
        assert!(buf.len() <= self.poll_write());
        // TODO core::ptr::volatile_copy_nonoverlapping_memory
        for i in 0..buf.len() {
            let off = ((self.private_offset_w + i) % self.write.size) as isize;
            unsafe {
                write_volatile(self.write.buf.offset(off), buf[i])
            }
        }
        self.private_offset_w += buf.len();
        release();
    }

    pub fn notify_read(&self) {
        acquire();
        self.write.ctrl.offset_r.set(self.private_offset_r as u64);
        release();
        if self.read.ctrl.status.read(Status::NOTIFY_READ) == 1 {
            self.read.notification.signal();
        }
    }

    pub fn notify_write(&self) {
        acquire();
        self.write.ctrl.offset_w.set(self.private_offset_w as u64);
        release();
        if self.read.ctrl.status.read(Status::NOTIFY_WRITE) == 1 {
            self.write.notification.signal();
        }
    }

    pub fn enable_notify_read(&self) {
        self.write.ctrl.status.modify(Status::NOTIFY_READ.val(1));
    }

    pub fn enable_notify_write(&self) {
        self.write.ctrl.status.modify(Status::NOTIFY_WRITE.val(1));
    }

    pub fn disable_notify_read(&self) {
        self.write.ctrl.status.modify(Status::NOTIFY_READ.val(0));
    }

    pub fn disable_notify_write(&self) {
        self.write.ctrl.status.modify(Status::NOTIFY_WRITE.val(0));
    }

}

pub struct PacketRingBuffer {
    rb: RingBuffer,
}

impl PacketRingBuffer {

    pub fn new(rb: RingBuffer) -> Self {
        Self {
            rb,
        }
    }

    const HEADER_SIZE: usize = core::mem::size_of::<u32>();

    fn packet_size(buf: &[u8]) -> usize {
        Self::HEADER_SIZE + buf.len()
    }

    fn serialize_header(n: usize) -> Vec<u8> {
        let mut writer = vec![0; Self::HEADER_SIZE];
        LittleEndian::write_uint(writer.as_mut_slice(), n as u64, Self::HEADER_SIZE);
        writer
    }

    pub fn poll(&self) -> Option<usize> {
        if self.rb.poll_read() < Self::HEADER_SIZE {
            return None
        }
        let mut header = vec![0; Self::HEADER_SIZE];
        self.rb.peek(Self::HEADER_SIZE, header.as_mut_slice());
        let n = LittleEndian::read_uint(header.as_slice(), Self::HEADER_SIZE) as usize;
        // icecap_sel4::debug_println!("n: {:x}", n);
        if n > self.rb.poll_read() - Self::HEADER_SIZE {
            return None
        }
        Some(n)
    }

    pub fn read(&mut self) -> Option<Vec<u8>> {
        self.poll().map(|n| {
            let mut buf = vec![0; n];
            self.rb.skip(Self::HEADER_SIZE);
            self.rb.read(n, buf.as_mut_slice());
            buf
        })
    }

    pub fn write(&mut self, buf: &[u8]) -> bool {
        if self.rb.poll_write() < Self::packet_size(buf) {
            return false;
        }
        self.rb.write(Self::serialize_header(buf.len()).as_slice());
        self.rb.write(buf);
        true
    }

    pub fn notify_read(&self) {
        self.rb.notify_read()
    }

    pub fn notify_write(&self) {
        self.rb.notify_write()
    }

    pub fn enable_notify_read(&self) {
        self.rb.enable_notify_read();
    }

    pub fn enable_notify_write(&self) {
        self.rb.enable_notify_write();
    }

    pub fn disable_notify_read(&self) {
        self.rb.disable_notify_read();
    }

    pub fn disable_notify_write(&self) {
        self.rb.disable_notify_write();
    }

}
