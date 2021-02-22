use core::{
    ops::{Not, BitOr, BitOrAssign, BitAnd, BitAndAssign},
};

use crate::{
    sys,
};

pub type Word = sys::seL4_Word;
pub type Slot = sys::seL4_Word;
pub type Badge = sys::seL4_Word;

#[derive(Debug, Copy, Clone)]
pub struct CapRights(sys::seL4_CapRights_t);

impl CapRights {

    pub fn raw(self) -> sys::seL4_CapRights_t {
        self.0
    }

    fn from_raw(raw: sys::seL4_CapRights_t) -> Self {
        Self(raw)
    }

    pub fn new(grant_reply: bool, grant: bool, read: bool, write: bool) -> Self {
        Self::from_raw(unsafe {
            sys::seL4_CapRights_new(
                grant_reply as u64,
                grant as u64,
                read as u64,
                write as u64,
            )
        })
    }

    // TODO get and set individual fields without manually wrapping all seL4_CapRights_* (possibly
    // by relying on bitfield implementation of seL4_CapRights_t)

    pub fn read_write() -> Self {
        Self::new(false, false, true, true)
    }

    pub fn all_rights() -> Self {
        Self::new(true, true, true, true)
    }

    pub fn can_read() -> Self {
        Self::new(false, false, true, false)
    }

    pub fn can_write() -> Self {
        Self::new(false, false, false, true)
    }

    pub fn can_grant() -> Self {
        Self::new(false, true, false, false)
    }

    pub fn can_grant_reply() -> Self {
        Self::new(true, false, false, false)
    }

    pub fn no_write() -> Self {
        Self::new(true, true, true, false)
    }

    pub fn no_read() -> Self {
        Self::new(true, true, false, true)
    }

    pub fn no_rights() -> Self {
        Self::new(false, false, false, false)
    }

}

#[derive(Debug, Copy, Clone)]
pub struct MessageInfo(sys::seL4_MessageInfo_t);

impl MessageInfo {

    pub fn raw(self) -> sys::seL4_MessageInfo_t {
        self.0
    }

    pub fn from_raw(raw: sys::seL4_MessageInfo_t) -> Self {
        Self(raw)
    }

    pub fn new(label: Word, caps_unwrapped: Word, extra_caps: Word, length: Word) -> Self {
        Self::from_raw(unsafe {
            sys::seL4_MessageInfo_new(label, caps_unwrapped, extra_caps, length)
        })
    }

    pub fn empty() -> Self {
        Self::new(0, 0, 0, 0)
    }

    pub fn label(self) -> Word {
        unsafe {
            sys::seL4_MessageInfo_get_label(self.raw())
        }
    }

    pub fn length(self) -> Word {
        unsafe {
            sys::seL4_MessageInfo_get_length(self.raw())
        }
    }

}

#[derive(Debug, Copy, Clone)]
pub struct CNodeCapData(sys::seL4_CNode_CapData_t);

impl CNodeCapData {

    pub fn raw(self) -> Word {
        self.0.words[0]
    }

    fn from_raw(raw: sys::seL4_CNode_CapData_t) -> Self {
        Self(raw)
    }

    pub fn new(guard: u64, guard_size: u64) -> Self {
        Self::from_raw(unsafe {
            sys::seL4_CNode_CapData_new(guard, guard_size)
        })
    }

    pub fn skip(guard_size: u64) -> Self {
        Self::new(0, guard_size)
    }

}

#[derive(Debug, Copy, Clone)]
pub struct VMAttributes(sys::seL4_ARM_VMAttributes);

impl VMAttributes {
    pub const NONE: Self = Self(0);
    pub const PAGE_CACHEABLE: Self = Self(sys::seL4_ARM_VMAttributes_seL4_ARM_PageCacheable);
    pub const PARITY_ENABLED: Self = Self(sys::seL4_ARM_VMAttributes_seL4_ARM_ParityEnabled);
    pub const EXECUTE_NEVER: Self = Self(sys::seL4_ARM_VMAttributes_seL4_ARM_ExecuteNever);

    pub fn has(self, rhs: Self) -> bool {
        self.0 & rhs.0 != 0
    }

    pub(crate) fn raw(self) -> sys::seL4_ARM_VMAttributes {
        self.0
    }
}

impl Default for VMAttributes {
    fn default() -> Self {
        Self(sys::seL4_ARM_VMAttributes_seL4_ARM_Default_VMAttributes)
    }
}

impl Not for VMAttributes {
    type Output = Self;
    fn not(self) -> Self {
        Self(!self.0)
    }
}

impl BitOr for VMAttributes {
    type Output = Self;
    fn bitor(self, rhs: Self) -> Self {
        Self(self.0 | rhs.0)
    }
}

impl BitOrAssign for VMAttributes {
    fn bitor_assign(&mut self, rhs: Self) {
        self.0 |= rhs.0;
    }
}

impl BitAnd for VMAttributes {
    type Output = Self;
    fn bitand(self, rhs: Self) -> Self {
        Self(self.0 & rhs.0)
    }
}

impl BitAndAssign for VMAttributes {
    fn bitand_assign(&mut self, rhs: Self) {
        self.0 &= rhs.0;
    }
}

// TODO wrap
pub type UserContext = sys::seL4_UserContext;

// TODO hack (i32 <-> isize)
#[allow(non_camel_case_types)]
pub enum VCPUReg {
    SCTLR = sys::seL4_VCPUReg_SCTLR as isize,
    TTBR0 = sys::seL4_VCPUReg_TTBR0 as isize,
    TTBR1 = sys::seL4_VCPUReg_TTBR1 as isize,
    TCR = sys::seL4_VCPUReg_TCR as isize,
    MAIR = sys::seL4_VCPUReg_MAIR as isize,
    AMAIR = sys::seL4_VCPUReg_AMAIR as isize,
    CIDR = sys::seL4_VCPUReg_CIDR as isize,
    ACTLR = sys::seL4_VCPUReg_ACTLR as isize,
    CPACR = sys::seL4_VCPUReg_CPACR as isize,
    AFSR0 = sys::seL4_VCPUReg_AFSR0 as isize,
    AFSR1 = sys::seL4_VCPUReg_AFSR1 as isize,
    ESR = sys::seL4_VCPUReg_ESR as isize,
    FAR = sys::seL4_VCPUReg_FAR as isize,
    ISR = sys::seL4_VCPUReg_ISR as isize,
    VBAR = sys::seL4_VCPUReg_VBAR as isize,
    TPIDR_EL1 = sys::seL4_VCPUReg_TPIDR_EL1 as isize,
    VMPIDR_EL2 = sys::seL4_VCPUReg_VMPIDR_EL2 as isize,
    SP_EL1 = sys::seL4_VCPUReg_SP_EL1 as isize,
    ELR_EL1 = sys::seL4_VCPUReg_ELR_EL1 as isize,
    SPSR_EL1 = sys::seL4_VCPUReg_SPSR_EL1 as isize,
    CNTV_CTL = sys::seL4_VCPUReg_CNTV_CTL as isize,
    CNTV_CVAL = sys::seL4_VCPUReg_CNTV_CVAL as isize,
    CNTVOFF = sys::seL4_VCPUReg_CNTVOFF as isize,
}
