#![allow(dead_code)]
#![allow(unused_variables)]

use core::arch::aarch64::{__dsb, __dmb, SY};
use core::cmp::max;
use core::ops::Deref;
use core::ptr::{read_volatile, write_volatile};
use core::intrinsics::volatile_copy_nonoverlapping_memory;
use core::sync::atomic::{fence, Ordering};
use alloc::vec::Vec;
use alloc::boxed::Box;
use tock_registers::{registers::{ReadOnly, WriteOnly, ReadWrite}, register_bitfields, register_structs};

pub type Kick = Box<dyn Fn()>;

pub trait RingBufferPointer {
    fn from_address(address: usize) -> Self;
}

impl RingBufferPointer for *const u8 {
    fn from_address(address: usize) -> Self {
        address as Self
    }
}

impl RingBufferPointer for *mut u8 {
    fn from_address(address: usize) -> Self {
        address as Self
    }
}

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

fn hack_mb() {
    unsafe {
        __dsb(SY);
        __dmb(SY);
    }
}

fn acquire() {
    fence(Ordering::Acquire);
    // HACK
    hack_mb();
}

fn release() {
    fence(Ordering::Release);
    // HACK
    hack_mb();
}

pub struct RingBufferSide<T> {
    pub size: usize,
    pub ctrl: Ctrl,
    pub buf: T,
    pub kick: Kick,
}

unsafe impl Send for RingBufferSide<*const u8> {}
unsafe impl Send for RingBufferSide<*mut u8> {}

impl<T> RingBufferSide<T> {
    pub fn new(size: usize, ctrl_addr: usize, buf: T, kick: Kick) -> Self {
        Self {
            size,
            ctrl: Ctrl::new(ctrl_addr),
            buf: buf, // TODO
            kick,
        }
    }
}

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

    pub fn peek(&self, buf: &mut [u8]) {
        acquire();

        let offset = self.private_offset_r % self.read.size;
        let n1 = self.read.size - offset;
        let n = buf.len();

        let src = self.read.buf;
        let dst = buf.as_mut_ptr();

        unsafe {
            if n <= n1 {
                volatile_copy_nonoverlapping_memory(dst, src.offset(offset as isize), n);
            } else {
                volatile_copy_nonoverlapping_memory(dst, src.offset(offset as isize), n1);
                volatile_copy_nonoverlapping_memory(dst.offset(n1 as isize), src, n - n1);
            }
        }

        release();
    }

    pub fn skip(&mut self, n: usize) {
        acquire();
        debug_assert!(n <= self.poll_read());
        self.private_offset_r += n;
        release();
    }

    pub fn read(&mut self, buf: &mut [u8]) {
        self.peek(buf);
        self.skip(buf.len());
    }

    pub fn write(&mut self, buf: &[u8]) {
        acquire();
        debug_assert!(buf.len() <= self.poll_write());

        let offset = self.private_offset_w % self.write.size;
        let n1 = self.write.size - offset;
        let n = buf.len();

        let src = buf.as_ptr();
        let dst = self.write.buf;

        unsafe {
            if n <= n1 {
                volatile_copy_nonoverlapping_memory(dst.offset(offset as isize), src, n);
            } else {
                volatile_copy_nonoverlapping_memory(dst.offset(offset as isize), src, n1);
                volatile_copy_nonoverlapping_memory(dst, src.offset(n1 as isize), n - n1);
            }
        }

        self.private_offset_w += n;
        release();
    }

    pub fn notify_read(&self) {
        acquire();
        self.write.ctrl.offset_r.set(self.private_offset_r as u64);
        release();
        if self.read.ctrl.status.read(Status::NOTIFY_READ) == 1 {
            (self.read.kick)();
        }
    }

    pub fn notify_write(&self) {
        acquire();
        self.write.ctrl.offset_w.set(self.private_offset_w as u64);
        release();
        if self.read.ctrl.status.read(Status::NOTIFY_WRITE) == 1 {
            (self.write.kick)();
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

    fn serialize_header(n: usize) -> [u8; Self::HEADER_SIZE] {
        (n as u32).to_le_bytes()
    }

    pub fn poll(&self) -> Option<usize> {
        if self.rb.poll_read() < Self::HEADER_SIZE {
            return None
        }
        let mut header = [0; Self::HEADER_SIZE];
        self.rb.peek(&mut header);
        let n = u32::from_le_bytes(header) as usize;
        if n > self.rb.poll_read() - Self::HEADER_SIZE {
            return None
        }
        Some(n)
    }

    pub fn read_into(&mut self, buf: &mut [u8]) {
        self.rb.skip(Self::HEADER_SIZE);
        self.rb.read(buf);
    }

    pub fn read(&mut self) -> Option<Vec<u8>> {
        self.poll().map(|n| {
            let mut buf = vec![0; n];
            self.read_into(buf.as_mut_slice());
            buf
        })
    }

    pub fn write(&mut self, buf: &[u8]) -> bool {
        if self.rb.poll_write() < Self::packet_size(buf) {
            return false;
        }
        self.rb.write(&Self::serialize_header(buf.len()));
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
