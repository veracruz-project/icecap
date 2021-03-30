#![no_std]
#![no_main]
#![feature(format_args_nl)]

#[macro_use]
extern crate alloc;

use serde::{Serialize, Deserialize};

use icecap_std::prelude::*;
use icecap_std::config::{DescTimerClient, DescMappedRingBuffer};
use icecap_std::config_realize::{realize_timer_client, realize_mapped_ring_buffer};
use icecap_start_generic::declare_generic_main;

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    timer: DescTimerClient,
    con: DescMappedRingBuffer,
}

fn main(config: Config) -> Fallible<()> {
    println!("begin basic timer test");

    let timer = realize_timer_client(&config.timer);

    let rb = realize_mapped_ring_buffer(&config.con);
    let mut con = BufferedRingBuffer::new(rb);
    con.ring_buffer().enable_notify_read();
    con.ring_buffer().enable_notify_write();

    timer.periodic(0, 1000000000).unwrap();
    for i in 0..5 {
        let nfn = config.timer.wait;
        let _ = nfn.wait();
        con.tx(format!("timer fired {}\n", i).as_bytes());
    }

    // for i in 0..1000 {
    //     con.tx(format!("foo bar baz {}. ", i).as_bytes());
    // }

    // for i in 0..1000 {
    //     con.tx(format!("foo bar baz {}\n", i).as_bytes());
    // }

    con.tx("interact:\n".as_bytes());

    loop {
        let nfn = config.con.wait;
        let badge = nfn.wait();
        // R/W flipped from client's perspective
        if badge & ICECAP_RING_BUFFER_W_BADGE != 0 {
            con.rx_callback();
            while let Some(mut v) = con.rx() {
                for c in v.iter_mut() {
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
