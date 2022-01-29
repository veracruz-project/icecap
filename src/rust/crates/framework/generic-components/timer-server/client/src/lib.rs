#![no_std]

use icecap_rpc as rpc;
use icecap_sel4::*;
use icecap_generic_timer_server_types::{Result as TimerServerResult, *};

#[derive(Clone)]
pub struct TimerClient {
    ep: rpc::Client<Request>,
}

impl TimerClient {
    pub fn new(ep: Endpoint) -> Self {
        Self {
            ep: rpc::Client::new(ep),
        }
    }

    pub fn completed(&self) -> TimerServerResult<()> {
        self.ep.call(&Request::Completed)
    }

    pub fn periodic(&self, tid: TimerID, ns: Nanoseconds) -> TimerServerResult<()> {
        self.ep.call(&Request::Periodic { tid, ns })
    }

    pub fn oneshot_absolute(&self, tid: TimerID, ns: Nanoseconds) -> TimerServerResult<()> {
        self.ep.call(&Request::OneshotAbsolute { tid, ns })
    }

    pub fn oneshot_relative(&self, tid: TimerID, ns: Nanoseconds) -> TimerServerResult<()> {
        self.ep.call(&Request::OneshotRelative { tid, ns })
    }

    pub fn stop(&self, tid: TimerID) -> TimerServerResult<()> {
        self.ep.call(&Request::Stop { tid })
    }

    pub fn time(&self) -> Nanoseconds {
        self.ep.call(&Request::Time)
    }
}
