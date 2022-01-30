use crate::{sys, MessageInfo, Word};

pub fn reply(info: MessageInfo) {
    unsafe { sys::seL4_Reply(info.raw()) }
}

#[derive(Copy, Clone, Debug)]
pub struct MessageRegister(i32);

impl MessageRegister {
    #[inline]
    pub const fn new(i: i32) -> Self {
        assert!((i as u32) < MSG_MAX_LENGTH);
        Self(i)
    }

    pub fn set(self, v: Word) {
        unsafe { sys::seL4_SetMR(self.0, v) }
    }

    pub fn get(self) -> Word {
        unsafe { sys::seL4_GetMR(self.0) }
    }
}

// Rust doesn't allow exporting MessageRegister::MR_0 at the top-level
pub const MR_0: MessageRegister = MessageRegister::new(0);
pub const MR_1: MessageRegister = MessageRegister::new(1);
pub const MR_2: MessageRegister = MessageRegister::new(2);
pub const MR_3: MessageRegister = MessageRegister::new(3);
pub const MR_4: MessageRegister = MessageRegister::new(4);
pub const MR_5: MessageRegister = MessageRegister::new(5);
pub const MR_6: MessageRegister = MessageRegister::new(6);
pub const MR_7: MessageRegister = MessageRegister::new(7);

pub const MSG_MAX_LENGTH: u32 = sys::seL4_MsgMaxLength;
