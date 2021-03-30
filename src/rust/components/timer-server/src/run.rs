use icecap_std::prelude::*;
use icecap_timer_server_types::{*, Result as TimerServerResult};
use icecap_rpc_sel4::*;
use core::result;

use crate::{
    plat::timer_device,
    server::{
        Server, Error, ClientId, TimerId, Nanosecond,
    },
};

const INTERRUPT_BADGE: Word = 1;
const CLIENT_BADGE_START: Word = INTERRUPT_BADGE + 1;

mod label {
    use super::Word;
    pub const COMPLETED: Word = 1;
    pub const PERIODIC: Word = 2;
    pub const ONESHOT_ABSOLUTE: Word = 3;
    pub const ONESHOT_RELATIVE: Word = 4;
    pub const STOP: Word = 5;
    pub const TIME: Word = 6;
}

pub fn run(cspace: CNode, reply_ep: Endpoint, vmem: usize, ep_read: Endpoint, clients: Vec<Notification>) -> Fallible<()> {

    let timers_per_client = 1;

    let device = timer_device(vmem);
    let mut server = Server::new(clients, timers_per_client.into(), device);

    loop {
        // TODO can use seL4_ReplyRecv once switch to MCS
        let (recv_info, badge) = ep_read.recv();
        cspace.relative(reply_ep).save_caller()?;

        let reply_info = match badge {
            INTERRUPT_BADGE => {
                server.handle_interrupt();
                MessageInfo::empty()
            }
            _ => {
                let cid: usize = badge as usize - CLIENT_BADGE_START as usize;
                match rpc_server::recv(&recv_info) {
                    Request::Completed => panic!(), // rpc_server::prepare(server.completed(cid)),
                    Request::Periodic { tid, ns } => rpc_server::prepare(&server.periodic(cid, tid, ns as i64)),
                    Request::OneshotAbsolute { tid, ns } => rpc_server::prepare(&server.oneshot_absolute(cid, tid, ns as i64)),
                    Request::OneshotRelative { tid, ns } => rpc_server::prepare(&server.oneshot_relative(cid, tid, ns as i64)),
                    Request::Stop { tid } => rpc_server::prepare(&server.stop(cid, tid)),
                    Request::Time => rpc_server::prepare(&(server.time(cid) as u64)),
                }
            }
        };

        reply_ep.send(reply_info);
    }
}
