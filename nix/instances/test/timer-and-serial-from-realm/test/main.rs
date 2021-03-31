#![no_std]
#![no_main]
#![feature(format_args_nl)]
#![allow(unused_variables)]
#![allow(unused_imports)]
#![allow(unused_variables)]

#[macro_use]
extern crate alloc;

use icecap_std::prelude::*;
use icecap_std::config::{RingBufferConfig, DescTimerClient};

use serde::{Serialize, Deserialize};

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    timer: DescTimerClient,
    con: RingBufferConfig,
    ctrl_ep_write: Endpoint,
}

fn main(config: Config) -> Fallible<()> {
    debug_println!("present");
    let timer = realize_timer_client(&config.timer);
    let timer_wait = config.timer.wait;
    let ctrl_ep_write = config.ctrl_ep_write;

    let rb = RingBuffer::realize_resume(&config.con);
    let mut con = BufferedRingBuffer::new(rb);
    con.ring_buffer().enable_notify_read();
    con.ring_buffer().enable_notify_write();

    timer.periodic(0, 1000000000).unwrap();
    for i in 0..5 {
        let _ = timer_wait.wait();
        // println!("timer fired {}", i);
        con.tx(format!("timer fired {}\n", i).as_bytes());
    }

    con.tx("interact:\n".as_bytes());

    loop {
        let nfn = config.con.wait;
        let badge = nfn.wait();
        // R/W flipped from client's perspective
        if badge & ICECAP_RING_BUFFER_W_BADGE != 0 {
            con.rx_callback();
            while let Some(mut v) = con.rx() {
                for c in v.iter_mut() {
                    if *c == b'x' {
                        ctrl_ep_write.send(MessageInfo::empty());
                    }
                    if *c == b'\r' {
                        *c = b'\n';
                    }
                }
                con.tx(&v);
            }
        }
        if badge & ICECAP_RING_BUFFER_R_BADGE != 0 {
            con.tx_callback();
        }
    }

    Ok(())
}

const ICECAP_RING_BUFFER_R_BADGE: Badge = 0x1;
const ICECAP_RING_BUFFER_W_BADGE: Badge = 0x2;
