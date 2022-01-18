#![no_std]
#![no_main]

extern crate alloc;

use core::convert::TryInto;
use core::ops::Range;

use serde::{Serialize, Deserialize};

use dyndl_realize_simple::*;
use dyndl_realize_simple_config::*;
use icecap_std::prelude::*;
use icecap_start_generic::declare_generic_main;

declare_generic_main!(main);

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Config {
    realizer: ConfigRealizer,
    subsystem_spec: Range<usize>,
    nfn: Notification,
}

fn main(config: Config) -> Fallible<()> {
    debug_println!("Hello from supersystem");

    let subsystem_spec_raw = unsafe {
        core::slice::from_raw_parts(
            config.subsystem_spec.start as *const u8,
            config.subsystem_spec.len(),
            )
    };

    let subsystem_spec = postcard::from_bytes(&subsystem_spec_raw).unwrap();

    let mut realizer = initialize_simple_realizer_from_config(&config.realizer)?;

    for _ in 0..3 {
        debug_println!("Realizing subsystem");
        let subsystem = realizer.realize(&subsystem_spec)?;

        for (affinity, virtual_core) in subsystem.virtual_cores.iter().enumerate() {
            for virtual_core_tcb in virtual_core.tcbs.iter() {
                let tcb = virtual_core_tcb.cap;
                tcb.set_affinity(affinity.try_into().unwrap())?;
                if virtual_core_tcb.resume {
                    tcb.resume()?;
                }
            }
        }

        let _badge = config.nfn.wait();

        debug_println!("Destroying subsystem");
        realizer.destroy(subsystem)?;
    }

    Ok(())
}
