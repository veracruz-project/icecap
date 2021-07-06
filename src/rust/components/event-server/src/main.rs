#![no_std]
#![no_main]
#![feature(drain_filter)]
#![feature(format_args_nl)]
#![feature(never_type)]
#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_variables)]
#![allow(unreachable_code)]

extern crate alloc;

use core::{
    cell::RefCell,
};
use alloc::{
    vec::Vec,
    collections::BTreeMap,
    rc::Rc,
    sync::Arc,
};

use biterate::biterate;

use icecap_std::{
    prelude::*,
    sync::*,
};
use icecap_rpc_sel4::*;
use icecap_event_server_types::*;
use icecap_event_server_config::*;

mod server;

use server::*;

declare_main!(main);

const BADGE_TYPE_MASK: Badge = 3 << 11;
const BADGE_TYPE_CLIENT: Badge = 3;
const BADGE_TYPE_CONTROL: Badge = 1;

pub fn main(config: Config) -> Fallible<()> {

    let server = EventServerConfig {
        host_notifications: config.host_notifications,
        realm_notifications: config.realm_notifications,
        resource_server_subscriptions: config.resource_server_subscriptions,
        irqs: config.irqs,
    }.realize();
    let server = Arc::new(Mutex::new(ExplicitMutexNotification::new(config.lock), server));

    for irq_thread_config in &config.irq_threads {
        irq_thread_config.thread.start({
            let irq_thread = IRQThread {
                notification: irq_thread_config.notification,
                irqs: irq_thread_config.irqs.clone(),
                server: server.clone(),
            };
            move || {
                irq_thread.run().unwrap()
            }
        })
    }

    let badges = Arc::new(config.badges);

    for (endpoint, thread) in config.endpoints.iter().skip(1).zip(&config.secondary_threads) {
        thread.start({
            let server = server.clone();
            let badges = badges.clone();
            let endpoint = *endpoint;
            move || {
                run(&server, endpoint, &badges).unwrap()
            }
        })
    }

    run(&server, config.endpoints[0], &badges)?;
    
    Ok(())
}

fn run(server: &Mutex<EventServer>, endpoint: Endpoint, badges: &Badges) -> Fallible<!> {
    loop {
        let (info, badge) = endpoint.recv();
        let badge_type = badge >> 11;
        let badge_value = badge & !BADGE_TYPE_MASK;
        match badge_type {
            BADGE_TYPE_CLIENT => {
                let req = rpc_server::recv::<calls::Client>(&info);
                let mut server = server.lock();
                let client = match badges.client_badges[badge_value as usize] {
                    ClientId::ResourceServer => {
                        &mut server.resource_server
                    }
                    ClientId::SerialServer => {
                        &mut server.serial_server
                    }
                    ClientId::Host => {
                        &mut server.host
                    }
                    ClientId::Realm(rid) => {
                        server.realms.get_mut(&rid).unwrap()
                    }
                };
                match req {
                    calls::Client::Signal { index } => {
                        rpc_server::reply(&client.signal(index)?)
                    }
                    calls::Client::SEV { nid } => {
                        rpc_server::reply(&client.sev(nid)?)
                    }
                    calls::Client::Poll { nid } => {
                        rpc_server::reply(&client.poll(nid)?)
                    }
                    calls::Client::End { nid, index } => {
                        rpc_server::reply(&client.end(nid, index)?)
                    }
                    calls::Client::Configure { nid, index, action } => {
                        rpc_server::reply(&client.configure(nid, index, action)?)
                    }
                    calls::Client::Move { src_nid, src_index, dst_nid, dst_index } => {
                        rpc_server::reply(&client.move_(src_nid, src_index, dst_nid, dst_index)?)
                    }
                }
            }
            BADGE_TYPE_CONTROL => {
                if badge_value == badges.resource_server_badge {
                    let req = rpc_server::recv::<calls::ResourceServer>(&info);
                    let mut server = server.lock();
                    match req {
                        calls::ResourceServer::Subscribe { nid, host_nid } => {
                            rpc_server::reply(&server.resource_server_subscribe(nid, host_nid)?)
                        }
                        calls::ResourceServer::CreateRealm { realm_id, num_nodes } => {
                            rpc_server::reply(&server.create_realm(realm_id, num_nodes)?)
                        }
                        calls::ResourceServer::DestroyRealm { realm_id } => {
                            rpc_server::reply(&server.destroy_realm(realm_id)?)
                        }
                    }
                } else if badge_value == badges.host_badge {
                    let req = rpc_server::recv::<calls::Host>(&info);
                    let mut server = server.lock();
                    match req {
                        calls::Host::Subscribe { nid, realm_id, realm_nid } => {
                            rpc_server::reply(&server.host_subscribe(nid, realm_id, realm_nid)?)
                        }
                    }
                } else {
                    panic!()
                }
            }
            _ => {
                panic!()
            }
        }
    }
}
