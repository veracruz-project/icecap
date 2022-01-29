#![no_std]
#![feature(never_type)]

mod mutex;

pub use mutex::{
    DeferredMutex, DeferredMutexGuard, DeferredMutexNotification, ExplicitMutexNotification,
    GenericMutex, GenericMutexGuard, Mutex, MutexGuard, MutexNotification,
};

// for macro
#[doc(hidden)]
pub mod _macro_helpers {
    pub use icecap_sel4::{LocalCPtr, Notification};
}
