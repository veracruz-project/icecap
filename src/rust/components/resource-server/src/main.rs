#![no_std]
#![no_main]
#![feature(format_args_nl)]
#![feature(never_type)]
#![feature(core_intrinsics)]
#![allow(unused_variables)]
#![allow(unused_imports)]

#[macro_use]
extern crate alloc;

use icecap_std::{
    prelude::*,
    sync::*,
};
use icecap_std::finite_set::Finite;
use icecap_std::config::RingBufferKicksConfig;
use icecap_resource_server_config::*;
use icecap_resource_server_types::*;
use icecap_resource_server_core::*;
use icecap_timer_server_client::*;
use icecap_rpc_sel4::*;

use icecap_event_server_types::calls::Client as EventServerRequest;
use icecap_event_server_types::{self as event_server, events};

mod realize_config;
use realize_config::*;

use core::intrinsics::volatile_copy_nonoverlapping_memory;
use alloc::{
    vec::Vec,
    collections::BTreeMap,
    rc::Rc,
    sync::Arc,
};

declare_main!(main);

fn main(config: Config) -> Fallible<()> {
    // Unmap dummy pages in the ResourceServer CNode.
    config.small_page.unmap()?;
    config.large_page.unmap()?;

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

    let server = ResourceServer::new(initialization_resources, allocator, externs);
    let server = Arc::new(Mutex::new(ExplicitMutexNotification::new(config.lock), server));

    let bulk_region = config.host_bulk_region_start;
    let bulk_region_size = config.host_bulk_region_size;

    for (local, thread) in config.local.iter().skip(1).zip(&config.secondary_threads) {
        thread.start({
            let server = server.clone();
            let local = local.clone();
            move || {
                run(&server, &local, bulk_region, bulk_region_size).unwrap()
            }
        })
    }

    run(&server, &config.local[0], bulk_region, bulk_region_size)?;
    
    Ok(())
}

fn run(server: &Mutex<ResourceServer>, local: &Local, bulk_region: usize, bulk_region_size: usize) -> Fallible<!> {

    let event_server_client = local.event_server_client;
    let event_server_control = local.event_server_control;
    let endpoint = local.endpoint;
    let timer = TimerClient::new(local.timer_server_client);

    let bulk_region = bulk_region as *const u8;

    loop {
        let (info, badge) = endpoint.recv();

        {
            let mut resource_server = server.lock();

            if badge == 0 {
                match rpc_server::recv(&info) {
                    Request::Declare { realm_id, spec_size } => rpc_server::reply::<()>(&resource_server.declare(realm_id, spec_size)?),
                    Request::SpecChunk { realm_id, bulk_data_offset, bulk_data_size, offset } => {
                        assert!(bulk_data_offset + bulk_data_size <= bulk_region_size);
                        let mut content = vec![0; bulk_data_size];
                        unsafe {
                            volatile_copy_nonoverlapping_memory(content.as_mut_ptr(), bulk_region.offset(bulk_data_offset as isize), bulk_data_size);
                        }
                        resource_server.incorporate_spec_chunk(realm_id, offset, &content)?;
                        rpc_server::reply::<()>(&());
                    },
                    Request::FillChunk { realm_id, bulk_data_offset, bulk_data_size, object_index, fill_entry_index, offset } => {
                        todo!()
                    },
                    Request::Declare { realm_id, spec_size } => rpc_server::reply::<()>(&resource_server.declare(realm_id, spec_size)?),
                    Request::Realize { realm_id } => {
                        // HACK
                        RPCClient::<event_server::calls::ResourceServer>::new(event_server_control).call::<()>(&event_server::calls::ResourceServer::CreateRealm {
                            realm_id,
                            num_nodes: 1,
                        });
                        rpc_server::reply::<()>(&resource_server.realize(realm_id)?)
                    }
                    Request::Destroy { realm_id } => {
                        let response = rpc_server::reply::<()>(&resource_server.destroy(realm_id)?);
                        // HACK
                        RPCClient::<event_server::calls::ResourceServer>::new(event_server_control).call::<()>(&event_server::calls::ResourceServer::DestroyRealm {
                            realm_id,
                        });
                        response
                    }
                    Request::YieldTo { physical_node, realm_id, virtual_node, timeout } => {
                        todo!();
                    }
                    Request::HackRun { realm_id } => rpc_server::reply::<()>(&resource_server.hack_run(realm_id)?),
                }
            }
        }
    }
}
