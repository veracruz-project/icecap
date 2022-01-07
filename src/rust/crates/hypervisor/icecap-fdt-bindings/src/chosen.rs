use alloc::prelude::v1::*;
use core::ops::Range;

use serde::{Deserialize, Serialize};

use icecap_fdt::{DeviceTree, Node};

// TODO store 'Value's

#[derive(Default, Debug, Clone, Serialize, Deserialize)]
pub struct Chosen {
    bootargs: Option<Vec<String>>,
    initrd: Option<Range<usize>>,
    stdout_path: Option<String>,
    kaslr_seed: Option<u64>,
}

impl Chosen {
    pub fn set_bootargs(&mut self, bootargs: Vec<String>) -> &mut Self {
        self.bootargs = Some(bootargs);
        self
    }

    pub fn set_initrd(&mut self, initrd: Range<usize>) -> &mut Self {
        self.initrd = Some(initrd);
        self
    }

    pub fn set_stdout_path(&mut self, stdout_path: String) -> &mut Self {
        self.stdout_path = Some(stdout_path);
        self
    }

    pub fn set_kaslr_seed(&mut self, kaslr_seed: u64) -> &mut Self {
        self.kaslr_seed = Some(kaslr_seed);
        self
    }

    pub fn apply(&self, dt: &mut DeviceTree) {
        let spec = dt.root.get_size_spec();
        let mut node = Node::new();
        if let Some(ref bootargs) = self.bootargs {
            node.set_property("bootargs", bootargs.join(" ").as_str());
        }
        if let Some(ref initrd) = self.initrd {
            node.set_property("linux,initrd-start", spec.address(initrd.start));
            node.set_property("linux,initrd-end", spec.address(initrd.end));
        }
        if let Some(ref stdout_path) = self.stdout_path {
            node.set_property("stdout-path", stdout_path.as_str());
        }
        if let Some(kaslr_seed) = self.kaslr_seed {
            node.set_property("kaslr-seed", kaslr_seed);
        }
        dt.root.set_child("chosen", node);
    }
}
