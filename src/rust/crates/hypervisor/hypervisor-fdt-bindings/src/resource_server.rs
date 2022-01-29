use alloc::prelude::v1::*;
use core::ops::Range;

use serde::{Deserialize, Serialize};

use icecap_fdt::bindings::Cells;
use icecap_fdt::{DeviceTree, Node};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResourceServer {
    pub bulk_region: Range<usize>,
    pub endpoints: Vec<u64>,
}

impl ResourceServer {
    pub fn apply(&self, name: &str, dt: &mut DeviceTree) {
        use Cells::*;
        let spec = dt.root.get_size_spec();
        let mut node = Node::new();
        node.set_compatible("icecap,resource-server");
        // node.set_property_iter("interrupts", &[
        //     0, self.irq, 1,
        // ]);
        node.set_property_cells(
            "reg",
            spec,
            vec![
                Address(self.bulk_region.start),
                Size(self.bulk_region.len()),
            ],
        );
        node.set_property_cells(
            "endpoints",
            spec,
            self.endpoints.iter().map(|endpoint| Raw64(*endpoint)),
        );
        dt.root.set_child(name, node);
    }

    pub fn apply_with_default_name(&self, dt: &mut DeviceTree) {
        self.apply(
            &format!("icecap_resource_server@{:x}", self.bulk_region.start),
            dt,
        )
    }
}
