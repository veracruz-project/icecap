#![allow(unused_variables)]

use core::convert::TryFrom;
use core::ops::Range;

use icecap_core::prelude::*;

mod set;

use set::Set;

/// CRegion is a CNode with associated metadata.
#[derive(Debug)]
pub struct CRegion {
    /// RelativeCPtr to the CNode represented by this CRegion.
    pub root: RelativeCPtr,

    /// Guard of the CRegion's CNode.
    pub guard: u64,

    /// Bits in the guard of the CRegion's CNode.
    pub guard_size: u64,

    /// log_2 of the size of the CRegion's CNode.
    pub radix: usize,

    set: Set,
}

pub type Slot = usize;

impl CRegion {
    pub fn new(root: RelativeCPtr, guard: u64, guard_size: u64, radix: usize) -> Self {
        let mut set = Set::new();
        set.deposit(0..1 << radix);
        Self {
            root,
            guard,
            guard_size,
            radix,
            set,
        }
    }

    /// Allocate a single slot in the cregion.
    pub fn alloc(&mut self) -> Option<Slot> {
        match self.set.withdraw(1) {
            Some(range) => Some(range.start),
            None => None,
        }
    }

    pub fn alloc_range(&mut self, size: usize) -> Range<Slot> {
        todo!()
    }

    /// Free a single slot in the cregion.
    pub fn free(&mut self, slot: Slot) {
        self.set.deposit(slot..(slot + 1));
    }

    pub fn free_range(&mut self, slots: Range<Slot>) {
        todo!()
    }

    /// Create a CPtrWithDepth to a capability in a specified Slot.
    pub fn cptr_with_depth(&self, slot: Slot) -> CPtrWithDepth {
        let slot = u64::try_from(slot).unwrap();
        let radix = u64::try_from(self.radix).unwrap();

        let mut cptr: u64 = self.root.path.cptr.raw();

        cptr = (cptr << self.guard_size) | self.guard;

        cptr = (cptr << radix) | slot;

        CPtrWithDepth {
            cptr: CPtr::from_raw(cptr),
            depth: self.root.path.depth + usize::try_from(self.guard_size).unwrap() + self.radix,
        }
    }

    /// Create a RelativeCPtr to a capability in a specified Slot.
    pub fn relative_cptr(&self, slot: Slot) -> RelativeCPtr {
        RelativeCPtr {
            root: self.context(),
            path: self.cptr_with_depth(slot),
        }
    }

    pub fn context(&self) -> CNode {
        self.root.root
    }
}
