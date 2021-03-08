#![no_std]
#![no_main]
#![feature(format_args_nl)]
#![allow(unused_variables)]
#![allow(unused_imports)]

#[macro_use]
extern crate alloc;

use icecap_std::prelude::*;
use icecap_std::base_config_realize::{realize_mapped_ring_buffer, realize_timer_client};
use icecap_std::base_config::{DynamicUntyped};
use icecap_caput_config::*;
use icecap_caput_types::{Message, calls};
use icecap_caput_core::*;

mod realize_config;
use realize_config::*;

declare_main!(main);

fn main(config: Config) -> Fallible<()> {
    let host_ep_read = config.host_ep_read;
    let mut host_rb = PacketRingBuffer::new(realize_mapped_ring_buffer(&config.host_rb));
    let host_rb_wait = config.host_rb.wait;
    host_rb.enable_notify_read();
    host_rb.enable_notify_write();

    let timer = realize_timer_client(&config.timer);
    let ctrl_ep_read = config.ctrl_ep_read;

    let cregion = realize_cregion(&config.allocator_cregion);
    let allocator = {
        let mut builder = AllocatorBuilder::new(cregion);
        for DynamicUntyped { slot, size_bits, paddr, .. } in &config.untyped {
            builder.add_untyped(ElaboratedUntyped {
                cptr: *slot,
                size_bits: *size_bits,
                paddr: paddr.unwrap(), // HACK
            });
        }
        builder.build()
    };

    let initialization_resources = realize_initialization_resources(&config.initialization_resources);
    let externs = realize_externs(&config.externs);

    let mut caput = Caput::new(initialization_resources, allocator, externs);

    let err = |err| format_err!("failed to parse packet: {}", err);

    let mut state: Option<Message> = None;

    loop {
        let (info, badge) = host_ep_read.recv();

        let mut notify = false;
        loop {
            if let Some(packet) = host_rb.read() {
                notify = true;
                match state {
                    None => {
                        state = Some(Message::parse(&packet).map_err(err)?);
                    }
                    Some(message) => {
                        state = None;
                        match message {
                            Message::SpecChunk { realm_id, offset } => {
                                caput.incorporate_spec_chunk(realm_id, offset, &packet)?;
                            }
                            Message::FillChunk { realm_id, .. } => {
                                todo!()
                            }
                        }
                    }
                }
            } else {
                break
            }
        }
        if notify {
            host_rb.notify_read();
        }

        if badge == 0 {

            let length = match info.label() as usize {
                calls::DECLARE => {
                    let spec_size = MR_0.get() as usize;
                    let realm_id = caput.declare(spec_size)?;
                    MR_0.set(realm_id as u64);
                    1
                }
                calls::REALIZE => {
                    let realm_id = MR_0.get() as usize;
                    let num_nodes = MR_1.get() as usize;
                    caput.realize(realm_id, num_nodes)?;
                    0
                }
                // ...
                _ => {
                    panic!()
                }
            };

            reply(MessageInfo::new(0, 0, 0, length));
        }
    }
}
