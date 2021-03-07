use icecap_core::prelude::*;
use crate::{CRegion, Slot, ElaboratedUntyped};

pub struct AllocatorBuilder {
    cregion: CRegion,
    fragmentation_threshold_size_bits: usize,
    untyped: Vec<ElaboratedUntyped>,
}

impl AllocatorBuilder {

    pub fn new(cregion: CRegion) -> Self {
        Self {
            cregion,
            fragmentation_threshold_size_bits: 0,
            untyped: vec![],
        }
    }

    pub fn add_untyped(&mut self, untyped: ElaboratedUntyped) {
        self.untyped.push(untyped);
    }

    pub fn set_fragmentation_threshold_size_bits(&mut self, fragmentation_threshold_size_bits: usize) {
        self.fragmentation_threshold_size_bits = fragmentation_threshold_size_bits;
    }

    pub fn build(self) -> Allocator {
        Allocator {
            // ...
        }
    }
}

pub struct Allocator {
    // ...
}

impl Allocator {

    pub fn peek_space(&self, count_by_size_bits: &[usize]) -> bool {
        todo!()
    }

    pub fn create_cnode(&mut self, slots_size_bits: usize) -> Fallible<(CRegion, ElaboratedUntyped)> {
        todo!()
    }

    pub fn create_objects(&mut self, cregion: &mut CRegion, blueprints: &[ObjectBlueprint]) -> Fallible<(Vec<Slot>, Vec<ElaboratedUntyped>)> {
        todo!()
    }

    pub fn revoke_and_free(&mut self, untyped: &ElaboratedUntyped) -> Fallible<()> {
        todo!()
    }
}
