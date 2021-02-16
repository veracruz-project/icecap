use core::fmt::Display;
use crate::{Context, Fail, Error};

pub trait ResultExt<T, E> {

    fn context<D>(self, context: D) -> Result<T, Context<D>>
    where
        D: Display + Send + Sync + 'static;

    fn with_context<F, D>(self, f: F) -> Result<T, Context<D>>
    where
        F: FnOnce(&E) -> D,
        D: Display + Send + Sync + 'static;
}

impl<T, E: Fail> ResultExt<T, E> for Result<T, E> {

    fn context<D>(self, context: D) -> Result<T, Context<D>>
    where
        D: Display + Send + Sync + 'static,
    {
        self.map_err(|failure| failure.context(context))
    }

    fn with_context<F, D>(self, f: F) -> Result<T, Context<D>>
    where
        F: FnOnce(&E) -> D,
        D: Display + Send + Sync + 'static,
    {
        self.map_err(|failure| {
            let context = f(&failure);
            failure.context(context)
        })
    }
}

impl<T> ResultExt<T, Error> for Result<T, Error> {

    fn context<D>(self, context: D) -> Result<T, Context<D>>
    where
        D: Display + Send + Sync + 'static
    {
        self.map_err(|failure| failure.context(context))
    }

    fn with_context<F, D>(self, f: F) -> Result<T, Context<D>>
    where
        F: FnOnce(&Error) -> D,
        D: Display + Send + Sync + 'static
    {
        self.map_err(|failure| {
            let context = f(&failure);
            failure.context(context)
        })
    }
}
