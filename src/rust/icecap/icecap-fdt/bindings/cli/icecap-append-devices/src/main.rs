use std::env;
use std::fs;
use std::io::{self, Read, Write};
use serde::{Serialize, Deserialize};

use icecap_fdt::DeviceTree;
use icecap_fdt_bindings::{
    Chosen,
    Device, RingBuffer,
};

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Input {
    chosen: Option<Chosen>,
    devices: Vec<Device<RingBuffer>>,
    num_cpus: usize,
}

fn main() -> Result<(), std::io::Error> {
    let path = env::args().nth(1).unwrap();
    let f = fs::File::open(path)?;
    let input: Input = serde_json::from_reader(f)?;

    let mut dtb = vec![];
    io::stdin().read_to_end(&mut dtb)?;
    let mut dt = DeviceTree::read(&dtb).unwrap();

    if let Some(chosen) = input.chosen {
        chosen.apply(&mut dt);
    }
    for device in input.devices {
        device.apply(&mut dt);
    }

    let cpus = dt.root.get_child_mut("cpus").unwrap();
    let cpu_0 = cpus.get_child("cpu@0").unwrap().clone();
    for i in 1..input.num_cpus {
        let mut cpu_n = cpu_0.clone();
        cpu_n.set_property("reg", i as u32);
        cpus.set_child(format!("cpu@{}", i), cpu_n);
    }

    io::stdout().write_all(&dt.write())?;
    Ok(())
}
