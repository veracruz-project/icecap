use core::{fmt, mem, result};

use crate::sys;

pub type Result<T> = result::Result<T, Error>;

#[repr(u32)]
#[derive(Copy, Clone, Debug)]
pub enum Error {
    InvalidArgument = sys::seL4_Error_seL4_InvalidArgument,
    InvalidCapability = sys::seL4_Error_seL4_InvalidCapability,
    IllegalOperation = sys::seL4_Error_seL4_IllegalOperation,
    RangeError = sys::seL4_Error_seL4_RangeError,
    AlignmentError = sys::seL4_Error_seL4_AlignmentError,
    FailedLookup = sys::seL4_Error_seL4_FailedLookup,
    TruncatedMessage = sys::seL4_Error_seL4_TruncatedMessage,
    DeleteFirst = sys::seL4_Error_seL4_DeleteFirst,
    RevokeFirst = sys::seL4_Error_seL4_RevokeFirst,
    NotEnoughMemory = sys::seL4_Error_seL4_NotEnoughMemory,
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "seL4_Error: {:?}", self)
    }
}

impl Into<sys::seL4_Error> for Error {
    fn into(self) -> sys::seL4_Error {
        self as sys::seL4_Error
    }
}

impl Error {
    pub(crate) unsafe fn unchecked(err: sys::seL4_Error) -> Self {
        mem::transmute(err) // no reason to pattern match when err is returned from sys
    }

    // assumes ret \in seL4_Error
    // 'None' implies seL4_NoError
    pub(crate) fn from_ret(ret: sys::seL4_Error) -> Option<Self> {
        match ret {
            sys::seL4_Error_seL4_NoError => None,
            err if err < sys::seL4_Error_seL4_NumErrors => Some(unsafe { Self::unchecked(err) }),
            _ => panic!("invalid seL4_Error: {}", ret),
        }
    }

    pub(crate) fn wrap(ret: u32) -> Result<()> {
        Self::or((), ret)
    }

    pub(crate) fn or<T>(r: T, ret: u32) -> Result<T> {
        match Self::from_ret(ret) {
            None => Ok(r),
            Some(err) => Err(err),
        }
    }
}
