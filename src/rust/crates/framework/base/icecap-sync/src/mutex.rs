use core::cell::UnsafeCell;
use core::ops::{Deref, DerefMut};
use core::sync::atomic::{fence, AtomicIsize, AtomicU64, Ordering};

use icecap_sel4::{LocalCPtr, Notification};

pub trait MutexNotification {
    type SetInput;
    type SetOutput;

    fn get(&self) -> Notification;

    fn set(&self, input: Self::SetInput) -> Self::SetOutput;
}

struct RawGenericMutex<N> {
    notification: N,
    value: AtomicIsize,
}

impl<N> RawGenericMutex<N> {
    pub const fn new(notification: N) -> Self {
        Self {
            notification,
            value: AtomicIsize::new(1),
        }
    }
}

impl<N: MutexNotification> RawGenericMutex<N> {
    fn lock(&self) {
        let old_value = self.value.fetch_sub(1, Ordering::Acquire);
        if old_value <= 0 {
            self.notification.get().wait();
            fence(Ordering::Acquire);
        }
    }

    fn unlock(&self) {
        let old_value = self.value.fetch_add(1, Ordering::Release);
        if old_value < 0 {
            self.notification.get().signal();
        }
    }
}

pub struct GenericMutex<N, T: ?Sized> {
    raw: RawGenericMutex<N>,
    data: UnsafeCell<T>,
}

unsafe impl<N, T: ?Sized + Send> Send for GenericMutex<N, T> {}
unsafe impl<N, T: ?Sized + Send> Sync for GenericMutex<N, T> {}

pub struct GenericMutexGuard<'a, N: MutexNotification, T: ?Sized + 'a> {
    mutex: &'a GenericMutex<N, T>,
}

impl<N, T> GenericMutex<N, T> {
    pub const fn new(notification: N, val: T) -> Self {
        Self {
            raw: RawGenericMutex::new(notification),
            data: UnsafeCell::new(val),
        }
    }

    pub fn into_inner(self) -> T {
        self.data.into_inner()
    }
}

impl<N: MutexNotification, T> GenericMutex<N, T> {
    unsafe fn guard(&self) -> GenericMutexGuard<'_, N, T> {
        GenericMutexGuard { mutex: self }
    }

    pub fn lock(&self) -> GenericMutexGuard<'_, N, T> {
        self.raw.lock();
        unsafe { self.guard() }
    }

    pub fn set(&self, input: N::SetInput) -> N::SetOutput {
        self.raw.notification.set(input)
    }
}

impl<'a, N: MutexNotification, T: ?Sized + 'a> GenericMutexGuard<'a, N, T> {
    pub fn mutex(this: &Self) -> &'a GenericMutex<N, T> {
        this.mutex
    }
}

impl<'a, N: MutexNotification, T: ?Sized + 'a> Deref for GenericMutexGuard<'a, N, T> {
    type Target = T;

    fn deref(&self) -> &T {
        unsafe { &*self.mutex.data.get() }
    }
}

impl<'a, N: MutexNotification, T: ?Sized + 'a> DerefMut for GenericMutexGuard<'a, N, T> {
    fn deref_mut(&mut self) -> &mut T {
        unsafe { &mut *self.mutex.data.get() }
    }
}

impl<'a, N: MutexNotification, T: ?Sized + 'a> Drop for GenericMutexGuard<'a, N, T> {
    fn drop(&mut self) {
        self.mutex.raw.unlock();
    }
}

pub type Mutex<T> = GenericMutex<ExplicitMutexNotification, T>;
pub type MutexGuard<'a, T> = GenericMutexGuard<'a, ExplicitMutexNotification, T>;

pub struct ExplicitMutexNotification(Notification);

impl ExplicitMutexNotification {
    pub const fn new(notification: Notification) -> Self {
        Self(notification)
    }
}

impl MutexNotification for ExplicitMutexNotification {
    type SetInput = !;
    type SetOutput = !;

    fn get(&self) -> Notification {
        self.0
    }

    fn set(&self, input: Self::SetInput) -> Self::SetOutput {
        input
    }
}

pub type DeferredMutex<T> = GenericMutex<DeferredMutexNotification, T>;
pub type DeferredMutexGuard<'a, T> = GenericMutexGuard<'a, DeferredMutexNotification, T>;

pub struct DeferredMutexNotification(AtomicU64);

impl DeferredMutexNotification {
    pub const fn new() -> Self {
        Self(AtomicU64::new(0))
    }
}

impl MutexNotification for DeferredMutexNotification {
    type SetInput = Notification;
    type SetOutput = ();

    fn get(&self) -> Notification {
        let cap = self.0.load(Ordering::SeqCst);
        assert_ne!(cap, 0);
        Notification::from_raw(cap)
    }

    fn set(&self, input: Self::SetInput) -> Self::SetOutput {
        self.0.store(input.raw(), Ordering::SeqCst)
    }
}

#[macro_export]
macro_rules! unsafe_static_mutex {
    ($name:ident, $extern:ident) => {
        pub struct $name;

        impl $crate::MutexNotification for $name {
            type SetInput = !;
            type SetOutput = !;

            fn get(&self) -> $crate::_macro_helpers::Notification {
                extern "C" {
                    static $extern: u64;
                }
                let raw = unsafe { $extern };
                assert_ne!(raw, 0); // HACK
                $crate::_macro_helpers::LocalCPtr::from_raw(raw)
            }

            fn set(&self, input: Self::SetInput) -> Self::SetOutput {
                input
            }
        }
    };
}
