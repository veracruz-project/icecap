use core::ops::Range;
use alloc::prelude::v1::*;

use icecap_fdt::{DeviceTree, Node};
use icecap_fdt::bindings::{Cells, SizeSpec};

pub struct RealmConfig {
    pub cpu_compatible: String,
    pub memory: Range<usize>,
    pub gic_paddr_start: usize,
}

impl RealmConfig {

    pub fn render(&self) -> DeviceTree {
        use Cells::*;

        let mut root = Node::new();

        let spec = SizeSpec { address_cells: 2, size_cells: 2 };

        root.set_compatible("linux,dummy-virt");
        root.set_size_spec(spec);
        root.set_property("interrupt-parent", 1: u32);

        root.set_child(format!("memory@{:x}", self.memory.start), {
            let mut node = Node::new();
            node.set_property("device_type", "memory");
            node.set_property_cells("reg", spec, vec![
                Address(self.memory.start), Size(self.memory.len()),
            ]);
            node
        });

        root.set_child("cpus", {
            let mut node = Node::new();
            node.set_address_cells(1);
            node.set_size_cells(0);
            node.set_child("cpu@0", {
                let mut node = Node::new();
                node.set_compatible(&self.cpu_compatible);
                node.set_property("device_type", "cpu");
                node.set_property("reg", 0: u32);
                node
            });
            node
        });

        root.set_child("timer", {
            let mut node = Node::new();
            node.set_compatible_iter(&["arm,armv8-timer", "arm,armv7-timer"]);
            node.set_empty_property("always-on");
            node.set_property_iter("interrupts", &[
                0x1, 0xd, 0x104,
                0x1, 0xe, 0x104,
                0x1, 0xb, 0x104,
                0x1, 0xa, 0x104: u32
            ]);
            node
            // TODO
            // plat/rpi4
            // < compatible = "arm,armv7-timer";
            // < interrupts = <0x1 0xd 0xf08 0x1 0xe 0xf08 0x1 0xb 0xf08 0x1 0xa 0xf08>;
            // < arm,cpu-registers-not-fw-configured;
            // plat/virt
            // > compatible = "arm,armv8-timer", "arm,armv7-timer";
            // > interrupts = <0x1 0xd 0x104 0x1 0xe 0x104 0x1 0xb 0x104 0x1 0xa 0x104>;
        });

        root.set_child(format!("gic400@{:x}", self.gic_paddr_start), {
            let mut node = Node::new();
            node.set_compatible("arm,gic-400");
            node.set_phandle(1);
            node.set_empty_property("interrupt-controller");
            node.set_interrupt_cells(3);
            node.set_property_iter("interrupts", &[
                0x1, 0x9, 0xf04: u32
            ]);
            node.set_property_cells("reg", spec, vec![
               Address(self.gic_paddr_start), Size(0x1000),
               Address(self.gic_paddr_start + 0x1000), Size(0x2000),
               Address(self.gic_paddr_start + 0x3000), Size(0x2000),
               Address(self.gic_paddr_start + 0x5000), Size(0x2000),
            ]);
            node
        });

        DeviceTree {
            mem_rsvmap: Vec::new(),
            root,
            boot_cpuid_phys: 0,
        }
    }
}
