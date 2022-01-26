use core::any::TypeId;
use core::fmt::{Debug, Display};
use alloc::boxed::Box;

use crate::backtrace::Backtrace;
use crate::context::Context;

/// The `Fail` trait.
///
/// Implementors of this trait are called 'failures'.
///
/// All error types should implement `Fail`, which provides a baseline of
/// functionality that they all share.
///
/// `Fail` has no required methods, but it does require that your type
/// implement several other traits:
///
/// - `Display`: to print a user-friendly representation of the error.
/// - `Debug`: to print a verbose, developer-focused representation of the
///   error.
/// - `Send + Sync`: Your error type is required to be safe to transfer to and
///   reference from another thread
///
/// Additionally, all failures must be `'static`. This enables downcasting.
///
/// `Fail` provides several methods with default implementations. Two of these
/// may be appropriate to override depending on the definition of your
/// particular failure: the `cause` and `backtrace` methods.
///
/// The `icecap-failure-derive` crate provides a way to derive the `Fail` trait for
/// your type.
pub trait Fail: Display + Debug + Send + Sync + 'static {
    /// Returns the "name" of the error.
    ///
    /// This is typically the type name. Not all errors will implement
    /// this. This method is expected to be most useful in situations
    /// where errors need to be reported to external instrumentation systems
    /// such as crash reporters.
    fn name(&self) -> Option<&str> {
        None
    }

    /// Returns a reference to the underlying cause of this failure, if it
    /// is an error that wraps other errors.
    ///
    /// Returns `None` if this failure does not have another error as its
    /// underlying cause. By default, this returns `None`.
    ///
    /// This should **never** return a reference to `self`, but only return
    /// `Some` when it can return a **different** failure. Users may loop
    /// over the cause chain, and returning `self` would result in an infinite
    /// loop.
    fn cause(&self) -> Option<&dyn Fail> {
        None
    }

    /// Returns a reference to the `Backtrace` carried by this failure, if it
    /// carries one.
    ///
    /// Returns `None` if this failure does not carry a backtrace. By
    /// default, this returns `None`.
    fn backtrace(&self) -> Option<&Backtrace> {
        None
    }

    /// Provides context for this failure.
    ///
    /// This can provide additional information about this error, appropriate
    /// to the semantics of the current layer. That is, if you have a
    /// lower-level error, such as an IO error, you can provide additional context
    /// about what that error means in the context of your function. This
    /// gives users of this function more information about what has gone
    /// wrong.
    ///
    /// This takes any type that implements `Display`, as well as
    /// `Send`/`Sync`/`'static`. In practice, this means it can take a `String`
    /// or a string literal, or another failure, or some other custom context-carrying
    /// type.
    fn context<D>(self, context: D) -> Context<D>
    where
        D: Display + Send + Sync + 'static,
        Self: Sized,
    {
        Context::with_err(context, self)
    }

    #[doc(hidden)]
    fn __private_get_type_id__(&self) -> TypeId {
        TypeId::of::<Self>()
    }
}

impl dyn Fail {
    /// Attempts to downcast this failure to a concrete type by reference.
    ///
    /// If the underlying error is not of type `T`, this will return `None`.
    pub fn downcast_ref<T: Fail>(&self) -> Option<&T> {
        if self.__private_get_type_id__() == TypeId::of::<T>() {
            unsafe { Some(&*(self as *const dyn Fail as *const T)) }
        } else {
            None
        }
    }

    /// Attempts to downcast this failure to a concrete type by mutable
    /// reference.
    ///
    /// If the underlying error is not of type `T`, this will return `None`.
    pub fn downcast_mut<T: Fail>(&mut self) -> Option<&mut T> {
        if self.__private_get_type_id__() == TypeId::of::<T>() {
            unsafe { Some(&mut *(self as *mut dyn Fail as *mut T)) }
        } else {
            None
        }
    }

    /// Returns the "root cause" of this `Fail` - the last value in the
    /// cause chain which does not return an underlying `cause`.
    ///
    /// If this type does not have a cause, `self` is returned, because
    /// it is its own root cause.
    ///
    /// This is equivalent to iterating over `iter_causes()` and taking
    /// the last item.
    pub fn find_root_cause(&self) -> &dyn Fail {
        let mut fail = self;
        while let Some(cause) = fail.cause() {
            fail = cause;
        }
        fail
    }

    /// Returns a iterator over the causes of this `Fail` with the cause
    /// of this fail as the first item and the `root_cause` as the final item.
    ///
    /// Use `iter_chain` to also include the fail itself.
    pub fn iter_causes(&self) -> Causes {
        Causes { fail: self.cause() }
    }

    /// Returns a iterator over all fails up the chain from the current
    /// as the first item up to the `root_cause` as the final item.
    ///
    /// This means that the chain also includes the fail itself which
    /// means that it does *not* start with `cause`.  To skip the outermost
    /// fail use `iter_causes` instead.
    pub fn iter_chain(&self) -> Causes {
        Causes { fail: Some(self) }
    }
}

impl Fail for Box<dyn Fail> {
    fn cause(&self) -> Option<&dyn Fail> {
        (**self).cause()
    }

    fn backtrace(&self) -> Option<&Backtrace> {
        (**self).backtrace()
    }
}

/// A iterator over the causes of a `Fail`
pub struct Causes<'f> {
    fail: Option<&'f dyn Fail>,
}

impl<'f> Iterator for Causes<'f> {
    type Item = &'f dyn Fail;
    fn next(&mut self) -> Option<&'f dyn Fail> {
        self.fail.map(|fail| {
            self.fail = fail.cause();
            fail
        })
    }
}
