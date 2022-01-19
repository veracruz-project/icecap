#![no_std]
#![no_main]

extern crate alloc;

use core::convert::TryInto;
use core::ops::Range;

use serde::{Deserialize, Serialize};

use dyndl_types::Model;
use dyndl_realize_simple::{initialize_simple_realizer_from_config, fill_frames_simple};
use dyndl_realize_simple_config::ConfigRealizer;
use icecap_start_generic::declare_generic_main;
use icecap_std::prelude::*;

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

    let (subsystem_spec, frame_fill): (Model, &[u8]) = postcard::take_from_bytes(&subsystem_spec_raw).unwrap();

    let mut realizer = initialize_simple_realizer_from_config(&config.realizer)?;

    for _ in 0..3 {
        debug_println!("Realizing subsystem");
        let subsystem = {
            let partial_subsystem = realizer.realize_start(subsystem_spec.clone())?;
            fill_frames_simple(&mut realizer, &partial_subsystem, frame_fill)?;
            realizer.realize_finish(partial_subsystem)?
        };

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
