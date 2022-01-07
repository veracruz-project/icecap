#![no_std]
#![no_main]

extern crate alloc;

use alloc::sync::Arc;

use icecap_std::prelude::*;
use icecap_std::sync::{Mutex, ExplicitMutexNotification};

declare_main!(main);

const INITIAL_VALUE: i32 = 0;

fn main(config: example_component_config::Config) -> Fallible<()> {
    debug_println!("{:#?}", config);

    let lock = Arc::new(Mutex::new(ExplicitMutexNotification::new(config.lock_nfn), INITIAL_VALUE));
    let barrier_nfn = config.barrier_nfn;

    config.secondary_thread.start({
        let lock = lock.clone();
        move || {
            {
                let mut value = lock.lock();
                *value += 1;
            }
            debug_println!("secondary thread");
            barrier_nfn.signal();
        }
    });

    {
        let mut value = lock.lock();
        *value += 1;
    }

    barrier_nfn.wait();

    debug_println!("primary thread");

    Ok(())
}
