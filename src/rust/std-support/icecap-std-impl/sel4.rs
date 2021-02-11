pub type Badge = u64;

mod c {
    type MessageInfo = u64;
    use super::Badge;

    extern "C" {

        #[link_name = "OUTLINE_MAGIC_seL4_DebugPutChar"]
        pub(super) fn seL4_DebugPutChar(c: u8);

        #[link_name = "OUTLINE_MAGIC_seL4_Call"]
        pub(super) fn seL4_Call(dest: u64, info: MessageInfo) -> MessageInfo;

        #[link_name = "OUTLINE_MAGIC_seL4_Signal"]
        pub(super) fn seL4_Signal(dest: u64);

        #[link_name = "OUTLINE_MAGIC_seL4_Wait"]
        pub(super) fn seL4_Wait(dest: u64, sender: *mut Badge);

        #[link_name = "OUTLINE_MAGIC_seL4_Poll"]
        pub(super) fn seL4_Poll(dest: u64, sender: *mut Badge) -> MessageInfo;

        #[link_name = "OUTLINE_MAGIC_seL4_MessageInfo_new"]
        pub(super) fn seL4_MessageInfo_new(
            label: u64,
            capsUnwrapped: u64,
            extraCaps: u64,
            length: u64,
        ) -> MessageInfo;

        #[link_name = "OUTLINE_MAGIC_seL4_MessageInfo_get_label"]
        pub(super) fn seL4_MessageInfo_get_label(info: MessageInfo) -> u64;

        #[link_name = "OUTLINE_MAGIC_seL4_MessageInfo_get_length"]
        pub(super) fn seL4_MessageInfo_get_length(info: MessageInfo) -> u64;

        #[link_name = "OUTLINE_MAGIC_seL4_GetMR"]
        pub fn seL4_GetMR(i: i32) -> u64;

        #[link_name = "OUTLINE_MAGIC_seL4_SetMR"]
        pub fn seL4_SetMR(i: i32, mr: u64);
    }
}

#[inline]
pub fn debug_put_char(c: u8) {
    unsafe {
        c::seL4_DebugPutChar(c)
    }
}

#[inline]
pub fn set_mr(i: i32, mr: u64) {
    unsafe {
        c::seL4_SetMR(i, mr)
    }
}

#[inline]
pub fn get_mr(i: i32) -> u64 {
    unsafe {
        c::seL4_GetMR(i)
    }
}

#[derive(Copy, Clone, Debug)]
pub struct Notification(u64);

impl Notification {

    pub const fn raw(self) -> u64 {
        self.0
    }

    pub const fn from_raw(raw: u64) -> Self {
        Self(raw)
    }

    #[inline]
    pub fn signal(self) {
        unsafe {
            c::seL4_Signal(self.raw());
        }
    }

    #[inline]
    pub fn wait(self) -> Badge {
        let mut badge = 0;
        unsafe {
            c::seL4_Wait(self.raw(), &mut badge);
        }
        badge
    }

    #[inline]
    pub fn poll(self) -> (MessageInfo, Badge) {
        let mut badge = 0;
        let info = unsafe {
            c::seL4_Poll(self.raw(), &mut badge)
        };
        (MessageInfo::from_raw(info), badge)
    }
}

#[derive(Copy, Clone, Debug)]
pub struct Endpoint(u64);

impl Endpoint {

    pub const fn raw(self) -> u64 {
        self.0
    }

    pub const fn from_raw(raw: u64) -> Self {
        Self(raw)
    }

    #[inline]
    pub fn call(self, info: MessageInfo) -> MessageInfo {
        unsafe {
            MessageInfo::from_raw(c::seL4_Call(self.raw(), info.raw()))
        }
    }
}

#[derive(Copy, Clone, Debug)]
pub struct MessageInfo(u64);

impl MessageInfo {

    pub const fn raw(self) -> u64 {
        self.0
    }

    pub const fn from_raw(raw: u64) -> Self {
        Self(raw)
    }

    #[inline]
    pub fn new(label: u64, caps_unwrapped: u64, extra_caps: u64, length: u64) -> Self {
        Self::from_raw(unsafe {
            c::seL4_MessageInfo_new(label, caps_unwrapped, extra_caps, length)
        })
    }

    #[inline]
    pub fn empty() -> Self {
        Self::new(0, 0, 0, 0)
    }

    #[inline]
    pub fn get_label(self) -> u64 {
        unsafe {
            c::seL4_MessageInfo_get_label(self.raw())
        }
    }

    #[inline]
    pub fn get_length(self) -> u64 {
        unsafe {
            c::seL4_MessageInfo_get_length(self.raw())
        }
    }
}
