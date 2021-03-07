use core::ops::Range;
use alloc::collections::BTreeMap;

pub struct Set {
    forward: BTreeMap<usize, usize>,
    backward: BTreeMap<usize, usize>,
}

impl Set {

    pub fn new() -> Self {
        Self {
            forward: BTreeMap::new(),
            backward: BTreeMap::new(),
        }
    }

    pub fn deposit(&mut self, range: Range<usize>) {
        // todo!()
    }

    pub fn withdraw(&mut self, n: usize) -> Range<usize> {
        todo!()
    }
}
