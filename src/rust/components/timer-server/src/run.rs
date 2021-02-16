use icecap_std::prelude::*;
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
                match recv_info.label() {
                    label::COMPLETED => {
                        MR_0.set(server.completed(cid));
                        MessageInfo::new(0, 0, 0, 1)
                    }
                    label::PERIODIC => {
                        MR_0.set(pack_result(server.periodic(cid, MR_0.get() as TimerId, MR_1.get() as Nanosecond)));
                        MessageInfo::new(0, 0, 0, 1)
                    }
                    label::ONESHOT_ABSOLUTE => {
                        MR_0.set(pack_result(server.oneshot_absolute(cid, MR_0.get() as TimerId, MR_1.get() as Nanosecond)));
                        MessageInfo::new(0, 0, 0, 1)
                    }
                    label::ONESHOT_RELATIVE => {
                        MR_0.set(pack_result(server.oneshot_relative(cid, MR_0.get() as TimerId, MR_1.get() as Nanosecond)));
                        MessageInfo::new(0, 0, 0, 1)
                    }
                    label::STOP => {
                        MR_0.set(pack_result(server.stop(cid, MR_0.get() as TimerId)));
                        MessageInfo::new(0, 0, 0, 1)
                    }
                    label::TIME => {
                        MR_0.set(server.time(cid) as Word);
                        MessageInfo::new(0, 0, 0, 1)
                    }
                    label => {
                        panic!("unexpected message label: {}", label)
                    }
                }
            }
        };

        reply_ep.send(reply_info);
    }
}

fn pack_result(r: result::Result<(), Error>) -> Word {
    r.err().unwrap_or(0) as Word
}
