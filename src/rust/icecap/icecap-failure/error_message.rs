use core::fmt::{self, Display, Debug};
use crate::{Fail, Error};

pub fn err_msg_as_error<D: Display + Debug + Sync + Send + 'static>(msg: D) -> Error {
    Error::from(ErrorMessage { msg })
}

pub fn err_msg<D: Display + Debug + Sync + Send + 'static>(msg: D) -> ErrorMessage<D> {
    ErrorMessage { msg }
    // NOTE
    // Error::from(ErrorMessage { msg })
    // ^ too easy to cause backtraces to be collected when a possible error is evaluated as an
    // argument rather than when it's thrown
}

#[derive(Debug)]
pub struct ErrorMessage<D: Display + Debug + Sync + Send + 'static> {
    msg: D,
}

impl<D: Display + Debug + Sync + Send + 'static> Fail for ErrorMessage<D> {
    fn name(&self) -> Option<&str> {
        Some("icecap_failure::ErrorMessage")
    }
}

impl<D: Display + Debug + Sync + Send + 'static> Display for ErrorMessage<D> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        Display::fmt(&self.msg, f)
    }
}
