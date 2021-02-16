use alloc::prelude::v1::*;
use core::mem::size_of;
use core::convert::{TryFrom, TryInto};
use core::ops::{Deref, DerefMut};

use crate::types::{DeviceTree, Node, Value};

// TODO is this the right way to have string keys?

pub const DEFAULT_ADDRESS_CELLS: u32 = 2;
pub const DEFAULT_SIZE_CELLS: u32 = 1;

impl DeviceTree {
}

impl Node {

    pub fn get_property<'a, K: Into<&'a str>, V: TryFrom<&'a Value>>(&'a self, name: K) -> Option<V> {
        self.properties.get(name.into()).and_then(|v: &Value| v.try_into().ok())
    }

    pub fn remove_property<'a, K: Into<&'a str>>(&mut self, name: K) -> Option<Value> {
        self.properties.remove(name.into())
    }

    pub fn set_property<K: Into<String>, V: Into<Value>>(&mut self, name: K, value: V) -> Option<Value> {
        self.properties.insert(name.into(), value.into())
    }

    // TODO unify with set_property
    pub fn set_property_iter<K: Into<String>, V: Into<Value>, T: IntoIterator<Item = V>>(&mut self, name: K, value: T) -> Option<Value> {
        self.set_property(name, Value::from_iter(value))
    }

    pub fn set_property_cell<K: Into<String>>(&mut self, name: K, spec: SizeSpec, value: Cells) -> Option<Value> {
        self.set_property(name, spec.cell(value))
    }

    pub fn set_property_cells<K: Into<String>, T: IntoIterator<Item = Cells>>(&mut self, name: K, spec: SizeSpec, value: T) -> Option<Value> {
        self.set_property_iter(name, value.into_iter().map(|v| spec.cell(v)))
    }

    pub fn set_empty_property<K: Into<String>>(&mut self, name: K) -> Option<Value> {
        self.set_property(name, Vec::new())
    }

    // TODO This shouldn't be necessary. Is it even more egonomic anyways?
    pub fn set_str_property<K: Into<String>>(&mut self, name: K, value: &str) -> Option<Value> {
        self.set_property(name, value)
    }

    pub fn get_child(&self, name: &str) -> Option<&Node> {
        self.children.get(name).map(|x| x.deref())
    }

    pub fn get_child_mut(&mut self, name: &str) -> Option<&mut Node> {
        self.children.get_mut(name).map(|x| x.deref_mut())
    }

    pub fn set_child<K: Into<String>>(&mut self, name: K, child: Node) -> Option<Box<Node>> {
        self.children.insert(name.into(), Box::new(child))
    }

    pub fn set_compatible(&mut self, value: &str) -> Option<Value> {
        self.set_property("compatible", value)
    }

    // TODO unify with set_compatible
    pub fn set_compatible_iter<V: Into<Value>, T: IntoIterator<Item = V>>(&mut self, value: T) -> Option<Value> {
        self.set_property_iter("compatible", value)
    }

    pub fn set_size_spec(&mut self, spec: SizeSpec) {
        self.set_address_cells(spec.address_cells);
        self.set_size_cells(spec.size_cells);
    }

    pub fn set_address_cells(&mut self, value: u32) {
        self.set_property("#address-cells", value);
    }

    pub fn set_size_cells(&mut self, value: u32) {
        self.set_property("#size-cells", value);
    }

    pub fn get_address_cells(&self) -> u32 {
        self.get_property("#address-cells").unwrap_or(DEFAULT_ADDRESS_CELLS)
    }

    pub fn get_size_cells(&self) -> u32 {
        self.get_property("#size-cells").unwrap_or(DEFAULT_SIZE_CELLS)
    }

    pub fn get_size_spec(&self) -> SizeSpec {
        SizeSpec {
            address_cells: self.get_address_cells(),
            size_cells: self.get_size_cells(),
        }
    }

    pub fn set_interrupt_cells(&mut self, value: u32) -> Option<Value> {
        self.set_property("#interrupt-cells", value)
    }

    pub fn set_phandle(&mut self, value: u32) -> Option<Value> {
        self.set_property("phandle", value)
    }
}

#[derive(Copy, Clone, Debug)]
pub struct SizeSpec {
    pub address_cells: u32,
    pub size_cells: u32,
}

impl SizeSpec {

    fn render(num_cells: u32, v: usize) -> Value {
        match num_cells {
            // TODO handle more cases (e.g. 0 is reasonable)
            // TODO consider limiting to valid cases by structuring SizeSpec further
            1 => (v as u32).into(),
            2 => (v as u64).into(),
            _ => panic!(),
        }
    }

    pub fn address(&self, v: usize) -> Value {
        Self::render(self.address_cells, v)
    }

    pub fn size(&self, v: usize) -> Value {
        Self::render(self.size_cells, v)
    }

    // TODO unsafe, should be Fallible<Value>, in case address or size is too large
    pub fn cell(&self, cells: Cells) -> Value {
        match cells {
            Cells::Address(v) => self.address(v),
            Cells::Size(v) => self.size(v),
            Cells::Raw32(v) => v.into(),
            Cells::Raw64(v) => v.into(),
        }
    }

}

#[derive(Copy, Clone, Debug)]
pub enum Cells {
    Address(usize),
    Size(usize),
    Raw32(u32),
    Raw64(u64),
}

impl Value {

    pub fn from_iter<V: Into<Value>, T: IntoIterator<Item = V>>(vs: T) -> Self {
        let mut raw = vec![];
        for v in vs {
            raw.extend(v.into().raw);
        }
        raw.into()
    }
}

impl<'a> From<&'a Value> for &'a [u8] {
    fn from(v: &'a Value) -> Self {
        &v.raw
    }
}

impl<'a> TryFrom<&'a Value> for u32 {
    type Error = ();
    fn try_from(v: &'a Value) -> Result<Self, Self::Error> {
        const SIZE: usize = size_of::<u32>();
        if v.raw.len() != SIZE {
            return Err(());
        }
        let mut be: [u8; SIZE] = [0; SIZE];
        be.copy_from_slice(&v.raw);
        Ok(u32::from_be_bytes(be))
    }
}

impl<'a> TryFrom<&'a Value> for u64 {
    type Error = ();
    fn try_from(v: &'a Value) -> Result<Self, Self::Error> {
        const SIZE: usize = size_of::<u64>();
        if v.raw.len() != SIZE {
            return Err(());
        }
        let mut be: [u8; SIZE] = [0; SIZE];
        be.copy_from_slice(&v.raw);
        Ok(u64::from_be_bytes(be))
    }
}

impl From<Vec<u8>> for Value {
    fn from(v: Vec<u8>) -> Self {
        Self::new(v)
    }
}

impl From<u32> for Value {
    fn from(v: u32) -> Self {
        v.to_be_bytes().to_vec().into()
    }
}

impl From<u64> for Value {
    fn from(v: u64) -> Self {
        v.to_be_bytes().to_vec().into()
    }
}

impl From<usize> for Value {
    fn from(v: usize) -> Self {
        v.to_be_bytes().to_vec().into()
    }
}

impl<V: Copy + Into<Value>> From<&V> for Value {
    fn from(v: &V) -> Self {
        (*v).into()
    }
}

impl From<&str> for Value {
    fn from(v: &str) -> Self {
        let mut raw = v.as_bytes().to_vec();
        raw.push(0);
        raw.into()
    }
}

// TODO

// impl<V: Into<Value>, T: IntoIterator<Item = V>> From<T> for Value {
//     fn from(v: T) -> Self {
//         Self::from_iter(v)
//     }
// }
