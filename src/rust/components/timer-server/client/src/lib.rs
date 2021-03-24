#![no_std]

use icecap_sel4::*;
use icecap_rpc_sel4::*;
use icecap_timer_server_types::{
    *, Result as TimerResult,
};

#[derive(Clone)]
pub struct Timer {
    ep: RPCEndpoint<Request>,
}

impl Timer {

    pub fn new(ep: Endpoint)-> Self {
        Self {
            ep: RPCEndpoint::new(ep),
        }
    }

    pub fn completed(&self) -> TimerResult<()> {
        self.ep.call::<response::Basic>(&Request::Completed).0
    }

    pub fn periodic(&self, tid: TimerID, ns: Nanoseconds) -> TimerResult<()> {
        self.ep.call::<response::Basic>(&Request::Periodic { tid, ns }).0
    }

    pub fn oneshot_absolute(&self, tid: TimerID, ns: Nanoseconds) -> TimerResult<()> {
        self.ep.call::<response::Basic>(&Request::OneshotAbsolute { tid, ns }).0
    }

    pub fn oneshot_relative(&self, tid: TimerID, ns: Nanoseconds) -> TimerResult<()> {
        self.ep.call::<response::Basic>(&Request::OneshotRelative { tid, ns }).0
    }

    pub fn stop(&self, tid: TimerID) -> TimerResult<()> {
        self.ep.call::<response::Basic>(&Request::Stop { tid }).0
    }

    pub fn time(&self) -> Nanoseconds {
        self.ep.call::<response::Time>(&Request::Time).ns
    }

}
