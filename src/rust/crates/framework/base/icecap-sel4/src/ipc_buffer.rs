use core::cell::RefCell;
use core::marker::PhantomData;
use core::mem;
use core::slice;

use crate::{sys, Word};

#[thread_local]
pub static IPC_BUFFER: RefCell<IPCBuffer> = RefCell::new(IPCBuffer {
    _marker: PhantomData,
});

/// The thread's IPC buffer.
///
/// When sending and receiving IPC messages, message data, capabilities, etc. may be written to or
/// read from the IPC buffer, which is set on the TCB.
pub struct IPCBuffer {
    // Instead of actually owning the seL4_IPCBuffer pointer, the impl uses the thread-local
    // __sel4_ipc_buffer which is set by the runtime. The marker field is here to indicate this and
    // ensure that IPCBuffer is !Send and !Sync.
    _marker: PhantomData<*mut sys::seL4_IPCBuffer>,
}

impl IPCBuffer {
    pub fn msg_regs(&self) -> &[Word] {
        &self.inner().msg[..]
    }

    pub fn msg_regs_mut(&mut self) -> &mut [Word] {
        &mut self.inner_mut().msg[..]
    }

    pub fn msg_bytes(&self) -> &[u8] {
        let msg = &self.inner().msg;
        let msg_ptr = msg as *const u64 as *const u8;
        let size = mem::size_of_val(msg);
        unsafe { slice::from_raw_parts(msg_ptr, size) }
    }

    pub fn msg_bytes_mut(&mut self) -> &mut [u8] {
        let msg = &mut self.inner_mut().msg;
        let msg_ptr = msg as *mut u64 as *mut u8;
        let size = mem::size_of_val(msg);
        unsafe { slice::from_raw_parts_mut(msg_ptr, size) }
    }

    pub fn user_data(&self) -> Word {
        self.inner().userData
    }

    pub fn set_user_data(&mut self, data: Word) {
        self.inner_mut().userData = data;
    }

    fn inner(&self) -> &sys::seL4_IPCBuffer {
        unsafe { &*sys::__sel4_ipc_buffer }
    }

    fn inner_mut(&mut self) -> &mut sys::seL4_IPCBuffer {
        unsafe { &mut *sys::__sel4_ipc_buffer }
    }

    pub fn with<F, T>(f: F) -> T
    where
        F: FnOnce(&IPCBuffer) -> T,
    {
        let ipc_buffer = IPC_BUFFER.borrow();
        f(&*ipc_buffer)
    }

    pub fn with_mut<F, T>(f: F) -> T
    where
        F: FnOnce(&mut IPCBuffer) -> T,
    {
        let mut ipc_buffer = IPC_BUFFER.borrow_mut();
        f(&mut *ipc_buffer)
    }
}
