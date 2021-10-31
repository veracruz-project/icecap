#![no_std]

mod mutex;

pub use mutex::{
    GenericMutex, GenericMutexGuard, MutexNotification,
    Mutex, MutexGuard, ExplicitMutexNotification,
};

// for macro
pub use icecap_sel4::{
    Notification, LocalCPtr,
};
