use core::any::TypeId;
use core::fmt::{self, Display, Debug};
use alloc::boxed::Box;

use crate::{Causes, Fail};
use crate::backtrace::Backtrace;
use crate::context::Context;

/// The `Error` type, which can contain any failure.
///
/// Functions which accumulate many kinds of errors should return this type.
/// All failures can be converted into it, so functions which catch those
/// errors can be tried with `?` inside of a function that returns this kind
/// of error.
///
/// In addition to implementing `Debug` and `Display`, this type carries `Backtrace`
/// information, and can be downcast into the failure that underlies it for
/// more detailed inspection.
pub struct Error {
    inner: Box<Inner<dyn Fail>>,
}

struct Inner<F: ?Sized + Fail> {
    backtrace: Backtrace,
    pub(crate) failure: F,
}

impl<F: Fail> From<F> for Error {
    fn from(failure: F) -> Self {
        let backtrace = match failure.backtrace() {
            None => Backtrace::new(),
            Some(_) => Backtrace::none(),
        };
        Self {
            inner: Box::new(Inner {
                failure,
                backtrace,
            })
        }
    }
}

impl Error {
    /// Return a reference to the underlying failure that this `Error`
    /// contains.
    pub fn as_fail(&self) -> &dyn Fail {
        &self.inner.failure
    }

    /// Returns the name of the underlying fail.
    pub fn name(&self) -> Option<&str> {
        self.as_fail().name()
    }

    /// Gets a reference to the `Backtrace` for this `Error`.
    ///
    /// If the failure this wrapped carried a backtrace, that backtrace will
    /// be returned. Otherwise, the backtrace will have been constructed at
    /// the point that failure was cast into the `Error` type.
    pub fn backtrace(&self) -> &Backtrace {
        self.as_fail().backtrace().unwrap_or(&self.inner.backtrace)
    }

    /// Provides context for this `Error`.
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
    /// or a string literal, or a failure, or some other custom context-carrying
    /// type.
    pub fn context<D: Display + Send + Sync + 'static>(self, context: D) -> Context<D> {
        Context::with_err(context, self)
    }

    /// Attempts to downcast this `Error` to a particular `Fail` type.
    ///
    /// This downcasts by value, returning an owned `T` if the underlying
    /// failure is of the type `T`. For this reason it returns a `Result` - in
    /// the case that the underlying error is of a different type, the
    /// original `Error` is returned.
    pub fn downcast<T: Fail>(self) -> Result<T, Error> {
        if self.as_fail().__private_get_type_id__() == TypeId::of::<T>() {
            Ok(unsafe {
                Box::from_raw(Box::into_raw(self.inner) as *mut Inner<T>)
            }.failure)
        } else {
            Err(self)
        }
    }

    /// Returns the "root cause" of this error - the last value in the
    /// cause chain which does not return an underlying `cause`.
    pub fn find_root_cause(&self) -> &dyn Fail {
        self.as_fail().find_root_cause()
    }

    /// Returns a iterator over the causes of this error with the cause
    /// of the fail as the first item and the `root_cause` as the final item.
    ///
    /// Use `iter_chain` to also include the fail of this error itself.
    pub fn iter_causes(&self) -> Causes {
        self.as_fail().iter_causes()
    }

    /// Returns a iterator over all fails up the chain from the current
    /// as the first item up to the `root_cause` as the final item.
    ///
    /// This means that the chain also includes the fail itself which
    /// means that it does *not* start with `cause`.  To skip the outermost
    /// fail use `iter_causes` instead.
    pub fn iter_chain(&self) -> Causes {
        self.as_fail().iter_chain()
    }

    /// Attempts to downcast this `Error` to a particular `Fail` type by
    /// reference.
    ///
    /// If the underlying error is not of type `T`, this will return `None`.
    pub fn downcast_ref<T: Fail>(&self) -> Option<&T> {
        self.as_fail().downcast_ref()
    }

    /// Attempts to downcast this `Error` to a particular `Fail` type by
    /// mutable reference.
    ///
    /// If the underlying error is not of type `T`, this will return `None`.
    pub fn downcast_mut<T: Fail>(&mut self) -> Option<&mut T> {
        self.inner.failure.downcast_mut()
    }
}

impl Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        Display::fmt(&self.inner.failure, f)?;
        if let Some(backtrace) = &self.inner.backtrace.internal {
            write!(f, "\nstack backtrace for error:\n\n    {}\n", backtrace.raw.serialize())?;
        }
        Ok(())
    }
}

// TODO
impl Debug for Error {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        Debug::fmt(&self.as_fail(), f)
    }
}

impl AsRef<dyn Fail> for Error {
    fn as_ref(&self) -> &dyn Fail {
        self.as_fail()
    }
}
