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

    pub const COMPLETED: Label = 1;
    pub const PERIODIC: Label = 2;
    pub const ONESHOT_ABSOLUTE: Label = 3;
    pub const ONESHOT_RELATIVE: Label = 4;
    pub const STOP: Label = 5;
    pub const TIME: Label = 6;
}

impl RPC for Request {

    fn send<T: Call>(&self) -> T {
        match *self {
            Request::Completed => T::simple(label::COMPLETED, &[]),
            Request::Periodic { tid, ns } => T::simple(label::PERIODIC, &[tid as ParameterValue, ns]),
            Request::OneshotAbsolute { tid, ns } => T::simple(label::ONESHOT_ABSOLUTE, &[tid as ParameterValue, ns]),
            Request::OneshotRelative { tid, ns } => T::simple(label::ONESHOT_RELATIVE, &[tid as ParameterValue, ns]),
            Request::Stop { tid } => T::simple(label::STOP, &[tid as ParameterValue]),
            Request::Time => T::simple(label::TIME, &[]),
        }
    }

    fn recv(call: impl Call) -> Self {
        match call.info().label {
            label::COMPLETED => Request::Completed,
            label::PERIODIC => Request::Periodic { tid: call.get(0) as TimerID, ns: call.get(1) as Nanoseconds },
            label::ONESHOT_ABSOLUTE => Request::OneshotAbsolute { tid: call.get(0) as TimerID, ns: call.get(1) as Nanoseconds },
            label::ONESHOT_RELATIVE => Request::OneshotRelative { tid: call.get(0) as TimerID, ns: call.get(1) as Nanoseconds },
            label::STOP => Request::Stop { tid: call.get(0) as TimerID },
            label::TIME => Request::Time,
            _ => panic!(),
        }
    }
}

pub mod response {
    use super::*;

    pub struct Basic(pub Result<()>);

    impl RPC for Basic {

        fn send<T: Call>(&self) -> T {
            match self.0 {
                Ok(()) => T::simple(0, &[]),
                Err(()) =>  T::simple(1, &[]),
            }
        }

        fn recv(call: impl Call) -> Self {
            Basic(match call.info().label {
                0 => Ok(()),
                1 => Err(()),
                _ => panic!(),
            })
        }
    }

    pub struct Time {
        pub ns: Nanoseconds,
    }

    impl RPC for Time {

        fn send<T: Call>(&self) -> T {
            let mut call = T::new(Info { label: 0, length: 1 });
            call.set(0, self.ns);
            call
        }

        fn recv(call: impl Call) -> Self {
            Self {
                ns: call.get(0),
            }
        }
    }
}
