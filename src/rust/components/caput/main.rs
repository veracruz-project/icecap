#![no_std]
#![no_main]
#![feature(format_args_nl)]
#![allow(unused_variables)]
#![allow(unused_imports)]
#![allow(unused_variables)]

#[macro_use]
extern crate alloc;

use core::ops::Range;
use core::slice;
use alloc::collections::btree_map::BTreeMap;
use serde::{Serialize, Deserialize};

use icecap_std::prelude::*;
use icecap_std::config_common::{DynamicUntyped, DescMappedRingBuffer, DescTimerClient};
use icecap_std::realize_config::{realize_mapped_ring_buffer, realize_timer_client};
use icecap_qemu_ring_buffer_server_config::Client as QEMUClient;
use icecap_caput_types::Message;
use dyndl_types::{Model, ExternObj};
use dyndl_realize::{Extern, Initializer, MyExtra, Config as DynDL, Externs, EvilPlan};

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    spec: Option<Range<usize>>,
    my: ConfigMy,
    my_extra: ConfigMyExtra,
    externs: BTreeMap<String, ConfigExtern>,
    ctrl_ep_read: Endpoint,
    host: QEMUClient,
    timer: DescTimerClient,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ConfigMy {
    cnode: CNode,
    asid_pool: ASIDPool,
    tcb_authority: TCB,
    pd: PGD,
    small_page_addr: usize,
    large_page_addr: usize,
}

impl Into<Initializer> for &ConfigMy {
    fn into(self) -> Initializer {
        Initializer {
            cnode: self.cnode,
            asid_pool: self.asid_pool,
            tcb_authority: self.tcb_authority,
            pd: self.pd,
            small_page_addr: self.small_page_addr,
            large_page_addr: self.large_page_addr,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct ConfigMyExtra {
    small_page: SmallPage,
    large_page: LargePage,
    free_slot: u64,
    untyped: Untyped,
}

impl Into<MyExtra> for &ConfigMyExtra {
    fn into(self) -> MyExtra {
        MyExtra {
            small_page: self.small_page,
            large_page: self.large_page,
            free_slot: self.free_slot,
            untyped: self.untyped,
        }
    }
}

#[derive(Debug, Clone, Eq, PartialEq, Serialize, Deserialize)]
struct ConfigExtern {
    ty: ExternObj,
    cptr: u64,
}

impl Into<Extern> for &ConfigExtern {
    fn into(self) -> Extern {
        Extern {
            ty: self.ty,
            cptr: Unspecified::from_raw(self.cptr),
        }
    }
}

fn read_packet(rb: &mut PacketRingBuffer, wait: Notification) -> Vec<u8> {
    loop {
        if let Some(packet) = rb.read() {
            rb.notify_read();
            break packet;
        }
        wait.wait();
    }
}

fn get_model(rb: &mut PacketRingBuffer, rb_wait: Notification, timer: &Timer) -> Fallible<Model> {
    let err = |err| format_err!("failed to parse packet: {}", err);
    let size = match Message::parse(&read_packet(rb, rb_wait)).map_err(err)? {
        Message::Start { size } => size,
        msg => bail!("unexpected message: {:?}", msg),
    };
    // let t_0 = timer.time();
    // debug_println!("size: {}", size);
    let mut buf = vec![0; size];
    loop {
        match Message::parse(&read_packet(rb, rb_wait)).map_err(err)? {
            Message::Chunk { range, content } => {
                // debug_println!("chunk: {:?}", range);
                buf[range].copy_from_slice(&content);
            }
            Message::End => {
                // debug_println!("end");
                break;
            }
            msg => bail!("unexpected message: {:?}", msg),
        };
    }
    // let t_1 = timer.time();
    let model = pinecone::from_bytes(&buf).map_err(err)?;
    // let t_2 = timer.time();
    // Ok((t_1 - t_0, t_2 - t_1, model))
    Ok(model)
}

fn main(config: Config) -> Fallible<()> {
    let timer = realize_timer_client(&config.timer);

    let externs = config.externs.iter().map(|(k, v)| (k.clone(), v.into())).collect();
    if let Some(ready_wait) = config.host.ready_wait {
        ready_wait.wait();
    }
    let mut host_rb = PacketRingBuffer::new(realize_mapped_ring_buffer(&config.host.rb));
    host_rb.enable_notify_read();
    host_rb.enable_notify_write();
    let host_rb_wait = config.host.rb.wait;
    let ctrl_ep_read = config.ctrl_ep_read;

    let ddl = DynDL {
        my: (&config.my).into(),
        my_extra: (&config.my_extra).into(),
        externs,
    };
    ddl.init()?;

    loop {
        // debug_println!("caput: getting model");
        // let (d_rx, d_parse, model) = get_model(&mut host_rb, host_rb_wait, &timer)?;
        let model = match &config.spec {
            None => {
                get_model(&mut host_rb, host_rb_wait, &timer)?
            }
            Some(spec) => {
                let spec = unsafe {
                    slice::from_raw_parts(spec.start as *const u8, spec.len())
                };
                pinecone::from_bytes(spec).unwrap()
            }
        };
        // let t_model = timer.time();
        debug_println!("caput: realizing realm");
        let plan = ddl.realize(&model)?;
        // let t_plan = timer.time();
        debug_println!("caput: running realm");
        let (_, _) = ctrl_ep_read.recv();
        // debug_println!("caput: destroying");
        ddl.destroy(plan)?;
        // debug_println!("d_rx: {}, d_parse: {}, d_plan: {}", d_rx, d_parse, t_plan - t_model);
    }
}
