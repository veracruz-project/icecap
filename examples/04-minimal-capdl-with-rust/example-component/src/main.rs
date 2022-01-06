#![no_std]
#![no_main]
#![feature(format_args_nl)]

extern crate alloc;

use alloc::sync::Arc;

use icecap_std::{
    prelude::*,
    sync::{Mutex, ExplicitMutexNotification},
    rpc_sel4::{RPCClient, rpc_server},
};

declare_main!(main);

const INITIAL_VALUE: i32 = 0;

fn main(config: example_component_config::Config) -> Fallible<()> {
    debug_println!("{:#?}", config);

    let lock = Arc::new(Mutex::new(ExplicitMutexNotification::new(config.lock_nfn), INITIAL_VALUE));

    config.secondary_thread.start({
        let lock = lock.clone();
        let ep = config.secondary_thread_ep_cap;
        move || {
            {
                let mut value = lock.lock();
                *value += 1;
            }
            let (info, _badge) = ep.recv();
            let request = rpc_server::recv::<i32>(&info);
            let response = {
                let value = lock.lock();
                *value == request
            };
            rpc_server::reply(&response);
        }
    });

    {
        let mut value = lock.lock();
        *value += config.foo.iter().sum::<i32>();
    }

    let guess = 7;
    let response = RPCClient::<i32>::new(config.primary_thread_ep_cap).call::<bool>(&guess);
    debug_println!("response: {}", response);

    Ok(())
}
