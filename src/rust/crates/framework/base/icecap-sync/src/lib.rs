#![no_std]

mod mutex;

pub use mutex::{
    ExplicitMutexNotification, GenericMutex, GenericMutexGuard, Mutex, MutexGuard,
    MutexNotification,
};

// for macro
#[doc(hidden)]
pub mod _macro_helpers {
    pub use icecap_sel4::{LocalCPtr, Notification};
}
