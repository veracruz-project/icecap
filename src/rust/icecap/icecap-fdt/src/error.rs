use core::result;
// use log;

#[derive(Debug)]
pub enum Error {
    Malformed,
}

pub type Result<T> = result::Result<T, Error>;

#[macro_export]
macro_rules! bail {
    ($e:expr) => {
        return Err($crate::warn_malformed!($e));
    };
    ($fmt:expr, $($arg:tt)*) => {
        return Err($crate::warn_malformed!($fmt, $($arg)*));
    };
}

#[macro_export]
macro_rules! ensure {
    ($cond:expr) => {
        if !($cond) {
            bail!("{}", stringify!($cond));
        }
    };
    ($cond:expr, $e:expr) => {
        if !($cond) {
            bail!($e);
        }
    };
    ($cond:expr, $fmt:expr, $($arg:tt)*) => {
        if !($cond) {
            bail!($fmt, $($arg)*);
        }
    };
}

#[macro_export]
macro_rules! warn_malformed {
    ($($arg:tt)*) => {
        { log::warn!($($arg)*); $crate::Error::Malformed }
    }
}
