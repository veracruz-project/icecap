//! Functions for interprocess communication (IPC) that doesn't touch the IPC buffer
//!
//! The IPC buffer is a thread-local region of memory that can be used to transfer large messages
//! and capabilities. To transfer messages that are at most 4 words long, these functions can be
//! used which are faster because they don't touch the IPC buffer.

use core::ptr;

use crate::{sys, Badge, Endpoint, LocalCPtr, MessageInfo, Word};

pub fn fast_send(endpoint: &Endpoint, label: Word, regs: &[Word]) {
    assert!(regs.len() <= 4);
    let mut reg_ptrs = [ptr::null_mut(); 4];
    for (reg, reg_ptr) in regs.iter().zip(reg_ptrs.iter_mut()) {
        *reg_ptr = reg as *const Word as *mut Word;
    }
    let info = MessageInfo::new(label, 0, 0, regs.len() as u64);
    unsafe {
        sys::seL4_SendWithMRs(
            endpoint.raw(),
            info.raw(),
            reg_ptrs[0],
            reg_ptrs[1],
            reg_ptrs[2],
            reg_ptrs[3],
        )
    };
}

pub fn fast_nb_send(endpoint: &Endpoint, label: Word, regs: &[Word]) {
    assert!(regs.len() <= 4);
    let mut reg_ptrs = [ptr::null_mut(); 4];
    for (reg, reg_ptr) in regs.iter().zip(reg_ptrs.iter_mut()) {
        *reg_ptr = reg as *const Word as *mut Word;
    }
    let info = MessageInfo::new(label, 0, 0, regs.len() as u64);
    unsafe {
        sys::seL4_NBSendWithMRs(
            endpoint.raw(),
            info.raw(),
            reg_ptrs[0],
            reg_ptrs[1],
            reg_ptrs[2],
            reg_ptrs[3],
        )
    };
}

pub struct FastRecvResult {
    label: Word,
    sender: Badge,
    size: usize,
    regs: [Word; 4],
}

impl FastRecvResult {
    pub fn label(&self) -> Word {
        self.label
    }

    pub fn sender(&self) -> Badge {
        self.sender
    }

    pub fn regs(&self) -> &[Word] {
        &self.regs[..self.size]
    }
}

pub fn fast_recv(endpoint: &Endpoint) -> FastRecvResult {
    let mut badge = 0;
    let mut regs = [0; 4];
    let raw_info = unsafe {
        sys::seL4_RecvWithMRs(
            endpoint.raw(),
            &mut badge,
            &mut regs[0],
            &mut regs[1],
            &mut regs[2],
            &mut regs[3],
        )
    };
    let info = MessageInfo::from_raw(raw_info);
    if info.length() >= 4 {
        panic!(
            "fast recv received {} registers, must be at most 4",
            info.length()
        );
    }
    if info.extra_caps() != 0 {
        panic!(
            "fast recv received {} capabilities, must be 0",
            info.extra_caps()
        );
    }
    FastRecvResult {
        label: info.label(),
        sender: badge,
        size: info.length() as usize,
        regs,
    }
}

pub struct FastCallResult {
    label: Word,
    size: usize,
    regs: [Word; 4],
}

impl FastCallResult {
    pub fn label(&self) -> Word {
        self.label
    }

    pub fn regs(&self) -> &[Word] {
        &self.regs[..self.size]
    }
}

pub fn fast_call(endpoint: &Endpoint, label: Word, args: &[Word]) -> FastCallResult {
    assert!(args.len() <= 4);
    let mut regs = [0; 4];
    regs.copy_from_slice(args);
    let send_info = MessageInfo::new(label, 0, 0, args.len() as u64);
    let raw_info = unsafe {
        sys::seL4_CallWithMRs(
            endpoint.raw(),
            send_info.raw(),
            &mut regs[0],
            &mut regs[1],
            &mut regs[2],
            &mut regs[3],
        )
    };
    let recv_info = MessageInfo::from_raw(raw_info);
    if recv_info.length() >= 4 {
        panic!(
            "fast call responded with {} registers, must be at most 4",
            recv_info.length()
        );
    }
    if recv_info.extra_caps() != 0 {
        panic!(
            "fast call responded with {} capabilities, must be 0",
            recv_info.extra_caps()
        );
    }
    FastCallResult {
        label: recv_info.label(),
        size: recv_info.length() as usize,
        regs,
    }
}

pub fn fast_reply(label: Word, regs: &[Word]) {
    assert!(regs.len() <= 4);
    let mut reg_ptrs = [ptr::null_mut(); 4];
    for (reg, reg_ptr) in regs.iter().zip(reg_ptrs.iter_mut()) {
        *reg_ptr = reg as *const Word as *mut Word;
    }
    let info = MessageInfo::new(label, 0, 0, regs.len() as u64);
    unsafe {
        sys::seL4_ReplyWithMRs(
            info.raw(),
            reg_ptrs[0],
            reg_ptrs[1],
            reg_ptrs[2],
            reg_ptrs[3],
        )
    };
}
