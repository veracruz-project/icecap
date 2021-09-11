// NOTE
// Be careful not to make it easy for a use to accidentally trigger the expensive collection of a
// backtrace for a `Fail` that's evaluated but never "thrown".

/// Exits a function early with an `Error`.
#[macro_export]
macro_rules! bail {
    ($e:expr) => {
        return Err($crate::err_msg_as_error($e))
    };
    ($fmt:expr, $($arg:tt)*) => {
        return Err($crate::err_msg_as_error(alloc::format!($fmt, $($arg)*)))
    };
}

/// Exits a function early with an `Error` if the condition is not satisfied.
/// Similar to `assert!`.
#[macro_export(local_inner_macros)]
macro_rules! ensure {
    ($cond:expr) => {
        if !($cond) {
            bail!("{}", _failure__stringify!($cond));
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

#[doc(hidden)]
#[macro_export]
macro_rules! _failure__stringify {
    ($($inner:tt)*) => {
        stringify! { $($inner)* }
    }
}

/// Constructs an `Error` using the standard string interpolation syntax.
#[macro_export]
macro_rules! format_err {
    ($($arg:tt)*) => { $crate::err_msg(alloc::format!($($arg)*)) }
}
