use std::error::Error;
use std::fmt;
use std::result;

pub type Result<T> = result::Result<T, Box<dyn Error>>;

#[derive(Debug)]
pub struct LameError {
    msg: String,
}

impl fmt::Display for LameError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", self.msg)
    }
}

impl Error for LameError {}

impl LameError {
    pub fn new(msg: String) -> Self {
        Self { msg }
    }
}

#[macro_export]
macro_rules! bail {
    ($e:expr) => {
        return Err($crate::format_err!($e));
    };
    ($fmt:expr, $($arg:tt)*) => {
        return Err($crate::format_err!($fmt, $($arg)*));
    };
}

#[macro_export]
macro_rules! ensure {
    ($cond:expr) => {
        if !($cond) {
            $crate::bail!("{}", stringify!($cond));
        }
    };
    ($cond:expr, $e:expr) => {
        if !($cond) {
            $crate::bail!($e);
        }
    };
    ($cond:expr, $fmt:expr, $($arg:tt)*) => {
        if !($cond) {
            $crate::bail!($fmt, $($arg)*);
        }
    };
}

#[macro_export]
macro_rules! format_err {
    ($($arg:tt)*) => { std::boxed::Box::new($crate::LameError::new(std::format!($($arg)*))) }
}
