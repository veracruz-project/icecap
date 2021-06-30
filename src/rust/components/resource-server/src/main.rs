#![no_std]
#![no_main]
#![feature(format_args_nl)]
#![allow(unused_variables)]
#![allow(unused_imports)]

#[macro_use]
extern crate alloc;

use icecap_std::prelude::*;
use icecap_std::finite_set::Finite;
use icecap_std::config::RingBufferKicksConfig;
use icecap_resource_server_config::*;
use icecap_resource_server_types::*;
use icecap_resource_server_core::*;
use icecap_timer_server_client::*;
use icecap_rpc_sel4::*;

use icecap_event_server_types::calls::Client as EventServerRequest;
use icecap_event_server_types::events;

mod realize_config;
use realize_config::*;

declare_main!(main);

fn main(config: Config) -> Fallible<()> {
    // Unmap dummy pages in the ResourceServer CNode.
    config.small_page.unmap()?;
    config.large_page.unmap()?;

    let event_server_client = config.event_server_client;

    let host_ep_read = config.host_ep_read;
    let mut host_rb = PacketRingBuffer::new(RingBuffer::realize(&config.host_rb, RingBufferKicksConfig {
        read: Box::new(move || {
            RPCClient::<EventServerRequest>::new(event_server_client).call(&EventServerRequest::Signal {
                index: events::ResourceServerOut::HostRingBuffer(events::RingBufferSide::Read).to_nat(),
            })
        }),
        write: Box::new(move || {
            RPCClient::<EventServerRequest>::new(event_server_client).call(&EventServerRequest::Signal {
                index: events::ResourceServerOut::HostRingBuffer(events::RingBufferSide::Write).to_nat(),
            })
        }),
    }));
    host_rb.enable_notify_read();
    host_rb.enable_notify_write();

    let timer = TimerClient::new(config.timer_ep_write);
    let ctrl_ep_read = config.ctrl_ep_read;

    let cregion = realize_cregion(&config.allocator_cregion);
    let allocator = {
        let mut builder = AllocatorBuilder::new(cregion);
        for DynamicUntyped { slot, size_bits, paddr, .. } in &config.untyped {
            builder.add_untyped(ElaboratedUntyped {
                cptr: *slot,
                untyped_id: UntypedId {
                    size_bits: *size_bits,
                    paddr: paddr.unwrap(), // HACK
                },
            });
        }
        builder.build()
    };

    let initialization_resources = realize_initialization_resources(&config.initialization_resources);
    let externs = realize_externs(&config.externs);

    let mut resource_server = ResourceServer::new(initialization_resources, allocator, externs);

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
                                resource_server.incorporate_spec_chunk(realm_id, offset, &packet)?;
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
            match rpc_server::recv(&info) {
                Request::Declare { realm_id, spec_size } => rpc_server::reply::<()>(&resource_server.declare(realm_id, spec_size)?),
                Request::Realize { realm_id } => rpc_server::reply::<()>(&resource_server.realize(realm_id)?),
                Request::Destroy { realm_id } => rpc_server::reply::<()>(&resource_server.destroy(realm_id)?),
                Request::YieldTo { physical_node, realm_id, virtual_node, timeout } => {
                    todo!();
                }
                Request::HackRun { realm_id } => rpc_server::reply::<()>(&resource_server.hack_run(realm_id)?),
            }
        }
    }
}
