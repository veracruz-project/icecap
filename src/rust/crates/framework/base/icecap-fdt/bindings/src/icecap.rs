use alloc::prelude::v1::*;
use core::ops::Range;

use serde::{Deserialize, Serialize};

use icecap_fdt::bindings::{Cells, SizeSpec};
use icecap_fdt::{DeviceTree, Node};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RingBuffer {
    pub read: RingBufferSide,
    pub write: RingBufferSide,
    pub kick: Kick,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RingBufferSide {
    pub ctrl: Range<usize>,
    pub data: Range<usize>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Kick {
    Raw { notification: u64 },
    Managed { endpoints: Vec<u64>, message: u64 },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Channel<T> {
    pub ring_buffer: T,
    pub irq: u32,
    pub name: String,
    pub id: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Con<T> {
    pub ring_buffer: T,
    pub irq: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Net<T> {
    pub ring_buffer: T,
    pub mtu: u32,
    pub mac_address: [u8; 6],
    pub irq: u32,
}

impl RingBuffer {
    fn set_reg(&self, node: &mut Node, spec: SizeSpec) {
        use Cells::*;
        node.set_property_cells(
            "reg",
            spec,
            vec![
                Address(self.read.ctrl.start),
                Size(self.read.ctrl.len()),
                Address(self.write.ctrl.start),
                Size(self.write.ctrl.len()),
                Address(self.read.data.start),
                Size(self.read.data.len()),
                Address(self.write.data.start),
                Size(self.write.data.len()),
            ],
        );
        match &self.kick {
            Kick::Raw { notification } => {
                node.set_property("kick-type", "unmanaged");
                node.set_property("kick-notification", notification);
            }
            Kick::Managed { endpoints, message } => {
                node.set_property("kick-type", "managed");
                node.set_property("kick-message", message);
                node.set_property_cells(
                    "kick-endpoints",
                    spec,
                    endpoints.iter().map(|endpoint| Raw64(*endpoint)),
                );
            }
        }
    }
}

impl Net<RingBuffer> {
    pub fn apply<K: Into<String>>(&self, name: K, dt: &mut DeviceTree) {
        let spec = dt.root.get_size_spec();
        let mut node = Node::new();
        node.set_compatible("icecap,net");
        node.set_property("mtu", self.mtu);
        node.set_property("local-mac-address", self.mac_address.to_vec());
        node.set_property_iter("interrupts", &[0, self.irq, 1]);
        self.ring_buffer.set_reg(&mut node, spec);
        dt.root.set_child(name, node);
    }
}

impl Con<RingBuffer> {
    pub fn apply(&self, name: &str, dt: &mut DeviceTree) {
        let spec = dt.root.get_size_spec();
        let mut node = Node::new();
        node.set_compatible("icecap,con");
        node.set_property_iter("interrupts", &[0, self.irq, 1]);
        self.ring_buffer.set_reg(&mut node, spec);
        dt.root.set_child(name, node);
    }
}

impl Channel<RingBuffer> {
    pub fn apply(&self, name: &str, dt: &mut DeviceTree) {
        let spec = dt.root.get_size_spec();
        let mut node = Node::new();
        node.set_compatible("icecap,channel");
        node.set_property("channel-name", self.name.as_str()); // property "name" is reserved
        node.set_property("id", self.id);
        node.set_property_iter("interrupts", &[0, self.irq, 1]);
        self.ring_buffer.set_reg(&mut node, spec);
        dt.root.set_child(name, node);
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Device<T> {
    Channel(Channel<T>),
    Net(Net<T>),
    Con(Con<T>),
}

impl Device<RingBuffer> {
    pub fn apply(&self, dt: &mut DeviceTree) {
        match self {
            Device::Channel(dev) => dev.apply(
                &format!("icecap_channel@{:x}", dev.ring_buffer.read.ctrl.start),
                dt,
            ),
            Device::Con(dev) => dev.apply(
                &format!("icecap_con@{:x}", dev.ring_buffer.read.ctrl.start),
                dt,
            ),
            Device::Net(dev) => dev.apply(
                &format!("icecap_net@{:x}", dev.ring_buffer.read.ctrl.start),
                dt,
            ),
        }
    }
}

impl<T> Device<T> {
    pub fn traverse<T_, E>(self, mut f: impl FnMut(T) -> Result<T_, E>) -> Result<Device<T_>, E> {
        Ok(match self {
            Device::Channel(Channel {
                ring_buffer,
                irq,
                name,
                id,
            }) => Device::Channel(Channel {
                ring_buffer: f(ring_buffer)?,
                irq,
                name,
                id,
            }),
            Device::Con(Con { ring_buffer, irq }) => Device::Con(Con {
                ring_buffer: f(ring_buffer)?,
                irq,
            }),
            Device::Net(Net {
                ring_buffer,
                mtu,
                mac_address,
                irq,
            }) => Device::Net(Net {
                ring_buffer: f(ring_buffer)?,
                mtu,
                mac_address,
                irq,
            }),
        })
    }
}
