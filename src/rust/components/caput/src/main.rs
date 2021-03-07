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
use icecap_caput_types::Message;
use icecap_caput_core::*;

mod realize_config;
use realize_config::*;

declare_main!(main);

fn main(config: Config) -> Fallible<()> {
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

    loop {

        let spec_size = match Message::parse(&read_packet(&mut host_rb, host_rb_wait)).map_err(err)? {
            Message::Start { size } => size,
            msg => bail!("unexpected message: {:?}", msg),
        };

        let realm_id = caput.declare(spec_size)?;

        loop {
            match Message::parse(&read_packet(&mut host_rb, host_rb_wait)).map_err(err)? {
                Message::Chunk { range } => {
                    let content = read_packet(&mut host_rb, host_rb_wait);
                    assert_eq!(range.len(), content.len());
                    caput.incorporate_spec_chunk(realm_id, range.start, &content)?;
                }
                Message::End => {
                    break;
                }
                msg => bail!("unexpected message: {:?}", msg),
            };
        }

        let num_nodes = 4;
        caput.realize(realm_id, num_nodes)?;

        for i in 0..num_nodes {
            caput.put(realm_id, i, i)?;
        }

        let (_, _) = ctrl_ep_read.recv();
        caput.destroy(realm_id)?;
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
