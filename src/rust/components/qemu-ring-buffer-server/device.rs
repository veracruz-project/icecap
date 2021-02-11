use core::ops::Deref;
use register::{mmio::*, register_structs};

const VAL_NOTIFY : u32 = 1;
const VAL_ACK    : u32 = 2;
const VAL_ENABLE : u32 = 3;

register_structs! {
    pub LayoutRegisterBlock {
        (0x000 => pub ctrl_r: WriteOnly<u64>),
        (0x008 => pub data_r: WriteOnly<u64>),
        (0x010 => pub size_r: WriteOnly<u64>),
        (0x018 => pub ctrl_w: WriteOnly<u64>),
        (0x020 => pub data_w: WriteOnly<u64>),
        (0x028 => pub size_w: WriteOnly<u64>),
        (0x030 => pub signal: WriteOnly<u32>),
        (0x034 => @END),
    }
}

#[derive(Clone, Copy)]
pub struct RingBufferDevice {
    base_addr: usize,
}

impl RingBufferDevice {

    pub fn new(base_addr: usize) -> Self {
        Self {
            base_addr,
        }
    }

    fn ptr(&self) -> *const LayoutRegisterBlock {
        self.base_addr as *const _
    }

    pub fn notify(&self) {
        self.signal.set(VAL_NOTIFY);
    }

    pub fn ack(&self) {
        self.signal.set(VAL_ACK);
    }

    pub fn enable(&self) {
        self.signal.set(VAL_ENABLE);
    }
}

impl Deref for RingBufferDevice {
    type Target = LayoutRegisterBlock;

    fn deref(&self) -> &Self::Target {
        unsafe {
            &*self.ptr()
        }
    }
}
