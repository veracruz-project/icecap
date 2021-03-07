use icecap_core::prelude::*;
use core::ops::Range;

mod set;
use set::Set;

pub struct CRegion {
    pub root: RelativeCPtr,
    pub guard: u64,
    pub guard_size: u64,
    pub slots_size_bits: usize,

    set: Set,
}

pub type Slot = usize;

impl CRegion {

    pub fn new(
        root: RelativeCPtr,
        guard: u64,
        guard_size: u64,
        slots_size_bits: usize,
        // TODO initial available ranges?
    ) -> Self {
        let mut set = Set::new();
        set.deposit(0 .. 1 << slots_size_bits);
        Self {
            root,
            guard,
            guard_size,
            slots_size_bits,
            set,
        }
    }

    pub fn alloc(&mut self) -> Option<Slot> {
        todo!()
    }

    pub fn alloc_range(&mut self, size: usize) -> Range<Slot> {
        todo!()
    }

    pub fn free(&mut self, slot: Slot) {
        todo!()
    }

    pub fn free_range(&mut self, slots: Range<Slot>) {
        todo!()
    }

    pub fn cptr(&self, slot: Slot) -> CPtr {
        todo!()
    }

    pub fn cptr_with_depth(&self, slot: Slot) -> CPtrWithDepth {
        todo!()
    }

    pub fn relative_cptr(&self, slot: Slot) -> RelativeCPtr {
        todo!()
    }

    pub fn context(&self) -> CNode {
        self.root.root
    }
}
