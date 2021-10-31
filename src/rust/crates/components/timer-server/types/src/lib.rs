#![no_std]

use serde::{Serialize, Deserialize};

pub type TimerID = i64;
pub type Nanoseconds = u64;

pub type Error = ();
pub type Result<T> = core::result::Result<T, Error>;

#[derive(Clone, Serialize, Deserialize)] // HACK
pub enum Request {
    Completed,
    Periodic { tid: TimerID, ns: Nanoseconds },
    OneshotAbsolute { tid: TimerID, ns: Nanoseconds },
    OneshotRelative { tid: TimerID, ns: Nanoseconds },
    Stop { tid: TimerID },
    Time,
}
