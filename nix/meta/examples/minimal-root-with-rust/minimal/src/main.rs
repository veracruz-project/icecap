#![no_std]
#![no_main]
#![feature(format_args_nl)]

extern crate alloc;

use icecap_std::prelude::*;
use icecap_std::sel4::{BootInfo, BootInfoExtraStructureId};
use icecap_fdt::DeviceTree;

declare_root_main!(main);

fn main(bootinfo: BootInfo) -> Fallible<()> {
    debug_println!("{:#?}", bootinfo.bootinfo);
    for extra in bootinfo.extra {
        match extra.id {
            BootInfoExtraStructureId::Fdt => {
                let dt = DeviceTree::read(extra.content).unwrap();
                debug_println!("fdt:");
                debug_println!("{}", dt);
            }
        }
    }
    Ok(())
}
