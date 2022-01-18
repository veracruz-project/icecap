#![no_std]
#![no_main]
#![feature(never_type)]
#![feature(core_intrinsics)]

extern crate alloc;

use dyndl_realize_simple::initialize_simple_realizer_from_config;
use icecap_resource_server_config::*;
use icecap_resource_server_core::*;
use icecap_resource_server_types::*;
use icecap_std::{prelude::*, rpc_sel4::*, sync::*};
use icecap_timer_server_client::*;

use icecap_event_server_types;
use icecap_event_server_types::calls::ResourceServer as EventServerRequest;

use alloc::sync::Arc;
use core::intrinsics::volatile_copy_nonoverlapping_memory;

const BADGE_HOST_CONTROL: Badge = 0x0;
const BADGE_HOST_YIELD: Badge = 0x1;
const BADGE_HOST_EVENT: Badge = 0x101;
const BADGE_TIMEOUT: Badge = 0x100;

declare_main!(main);

fn main(config: Config) -> Fallible<()> {
    let realizer = initialize_simple_realizer_from_config(&config.realizer)?;

    let server = ResourceServer::new(
        realizer,
        config.cnode,
        config
            .local
            .iter()
            .map(|local| NodeLocal {
                reply_slot: local.reply_slot,
                timer_server_client: TimerClient::new(local.timer_server_client),
                event_server_control: RPCClient::<EventServerRequest>::new(
                    local.event_server_control,
                ),
            })
            .collect(),
    );
    let server = Arc::new(Mutex::new(
        ExplicitMutexNotification::new(config.lock),
        server,
    ));

    let bulk_region = config.host_bulk_region_start;
    let bulk_region_size = config.host_bulk_region_size;

    for ((node_index, local), thread) in config
        .local
        .iter()
        .enumerate()
        .skip(1)
        .zip(&config.secondary_threads)
    {
        thread.start({
            let server = server.clone();
            let local = local.clone();
            move || {
                run(
                    &server,
                    node_index,
                    local.endpoint,
                    bulk_region,
                    bulk_region_size,
                )
                .unwrap()
            }
        })
    }

    run(
        &server,
        0,
        config.local[0].endpoint,
        bulk_region,
        bulk_region_size,
    )?
}

fn run(
    server: &Mutex<ResourceServer>,
    node_index: usize,
    endpoint: Endpoint,
    bulk_region: usize,
    bulk_region_size: usize,
) -> Fallible<!> {
    let bulk_region = bulk_region as *const u8;

    loop {
        let (info, badge) = endpoint.recv();

        {
            let mut resource_server = server.lock();

            match badge {
                BADGE_HOST_CONTROL =>
                {
                    #[allow(unused_variables)]
                    match rpc_server::recv(&info) {
                        Request::Declare {
                            realm_id,
                            spec_size,
                        } => {
                            rpc_server::reply::<()>(&resource_server.declare(realm_id, spec_size)?)
                        }
                        Request::SpecChunk {
                            realm_id,
                            bulk_data_offset,
                            bulk_data_size,
                            offset,
                        } => {
                            assert!(bulk_data_offset + bulk_data_size <= bulk_region_size);
                            let mut content = vec![0; bulk_data_size];
                            unsafe {
                                volatile_copy_nonoverlapping_memory(
                                    content.as_mut_ptr(),
                                    bulk_region.offset(bulk_data_offset as isize),
                                    bulk_data_size,
                                );
                            }
                            resource_server.incorporate_spec_chunk(realm_id, offset, &content)?;
                            rpc_server::reply::<()>(&());
                        }
                        Request::FillChunk {
                            realm_id,
                            bulk_data_offset,
                            bulk_data_size,
                            object_index,
                            fill_entry_index,
                            offset,
                        } => {
                            todo!()
                        }
                        Request::Realize { realm_id } => {
                            rpc_server::reply::<()>(&resource_server.realize(node_index, realm_id)?)
                        }
                        Request::Destroy { realm_id } => {
                            rpc_server::reply::<()>(&resource_server.destroy(node_index, realm_id)?)
                        }
                        Request::HackRun { realm_id } => {
                            rpc_server::reply::<()>(&resource_server.hack_run(realm_id)?)
                        }
                    }
                }
                BADGE_HOST_YIELD => {
                    let Yield {
                        physical_node,
                        realm_id,
                        virtual_node,
                        timeout,
                    } = rpc_server::recv(&info);
                    resource_server.yield_to(physical_node, realm_id, virtual_node, timeout)?;
                }
                BADGE_HOST_EVENT => {
                    //  debug_println!("host event on {}", node_index);
                    resource_server.host_event(node_index)?;
                }
                BADGE_TIMEOUT => {
                    // debug_println!("timeout on {}", node_index);
                    resource_server.timeout(node_index)?;
                }
                _ => {
                    panic!("badge: {}", badge)
                }
            }
        }
    }
}
