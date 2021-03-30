#![no_std]

use icecap_rpc::*;

pub type TimerID = i64;
pub type Nanoseconds = u64;

pub type Error = ();
pub type Result<T> = core::result::Result<T, Error>;

#[derive(Clone)] // HACK
pub enum Request {
    Completed,
    Periodic { tid: TimerID, ns: Nanoseconds },
    OneshotAbsolute { tid: TimerID, ns: Nanoseconds },
    OneshotRelative { tid: TimerID, ns: Nanoseconds },
    Stop { tid: TimerID },
    Time,
}

mod label {
    use super::*;

    pub const COMPLETED: ParameterValue = 1;
    pub const PERIODIC: ParameterValue = 2;
    pub const ONESHOT_ABSOLUTE: ParameterValue = 3;
    pub const ONESHOT_RELATIVE: ParameterValue = 4;
    pub const STOP: ParameterValue = 5;
    pub const TIME: ParameterValue = 6;
}

impl RPC for Request {

    fn send(&self, call: &mut impl WriteCall) {
        match *self {
            Request::Completed => call.write_all(&[label::COMPLETED]),
            Request::Periodic { tid, ns } => call.write_all(&[label::PERIODIC, tid as ParameterValue, ns]),
            Request::OneshotAbsolute { tid, ns } => call.write_all(&[label::ONESHOT_ABSOLUTE, tid as ParameterValue, ns]),
            Request::OneshotRelative { tid, ns } => call.write_all(&[label::ONESHOT_RELATIVE, tid as ParameterValue, ns]),
            Request::Stop { tid } => call.write_all(&[label::STOP, tid as ParameterValue]),
            Request::Time => call.write_all(&[label::TIME]),
        }
    }

    fn recv(call: &mut impl ReadCall) -> Self {
        match call.read() {
            label::COMPLETED => Request::Completed,
            label::PERIODIC => Request::Periodic { tid: call.read(), ns: call.read() },
            label::ONESHOT_ABSOLUTE => Request::OneshotAbsolute { tid: call.read(), ns: call.read() },
            label::ONESHOT_RELATIVE => Request::OneshotRelative { tid: call.read(), ns: call.read() },
            label::STOP => Request::Stop { tid: call.read() },
            label::TIME => Request::Time,
            _ => panic!(),
        }
    }
}
