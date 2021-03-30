#![no_std]

use icecap_sel4::*;
use icecap_rpc_sel4::*;
use icecap_timer_server_types::{*, Result as TimerResult};

#[derive(Clone)]
pub struct Timer {
    ep: RPCClient<Request>,
}

impl Timer {

    pub fn new(ep: Endpoint)-> Self {
        Self {
            ep: RPCClient::new(ep),
        }
    }

    pub fn completed(&self) -> TimerResult<()> {
        self.ep.call(&Request::Completed)
    }

    pub fn periodic(&self, tid: TimerID, ns: Nanoseconds) -> TimerResult<()> {
        self.ep.call(&Request::Periodic { tid, ns })
    }

    pub fn oneshot_absolute(&self, tid: TimerID, ns: Nanoseconds) -> TimerResult<()> {
        self.ep.call(&Request::OneshotAbsolute { tid, ns })
    }

    pub fn oneshot_relative(&self, tid: TimerID, ns: Nanoseconds) -> TimerResult<()> {
        self.ep.call(&Request::OneshotRelative { tid, ns })
    }

    pub fn stop(&self, tid: TimerID) -> TimerResult<()> {
        self.ep.call(&Request::Stop { tid })
    }

    pub fn time(&self) -> Nanoseconds {
        self.ep.call(&Request::Time)
    }
}
