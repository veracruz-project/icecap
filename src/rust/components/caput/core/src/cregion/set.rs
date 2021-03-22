use core::ops::Range;
use alloc::collections::BTreeMap;

#[derive(Debug)]
pub struct Set {
    elements: BTreeMap<usize, bool>,
    // forward: BTreeMap<usize, usize>,
    // backward: BTreeMap<usize, usize>,
}

impl Set {

    pub fn new() -> Self {
        Self {
            elements: BTreeMap::new(),
            // forward: BTreeMap::new(),
            // backward: BTreeMap::new(),
        }
    }

    /// Deposit a range of usable elements into the set.
    pub fn deposit(&mut self, range: Range<usize>) {
        for key in range {
            // Insert the element into the set and check that the element
            // was not already in the set.
            match self.elements.insert(key, false) {
                Some(false) => panic!("Attempting to insert elements already in the Set"),
                _ => {},
            }
        }
    }

    /// Withdraw a number of contiguous elements from the set.
    pub fn withdraw(&mut self, n: usize) -> Option<Range<usize>> {
        let mut num_found = 0;
        let mut low = 0;
        let mut high = 0;
        let mut building_range = false;
        let mut found_range = false;

        // Performs a naive search through the map for a contiguous range
        // of unused elements.
        for (key, used) in self.elements.iter() {
            if !used {
                if !building_range {
                    building_range = true;
                    low = *key;
                }
                num_found += 1;
                if num_found == n {
                    high = *key;
                    found_range = true;
                    break;
                }
            } else {
                // reset
                num_found = 0;
                low = 0;
                high = 0;
                building_range = false;
            }
        }

        if found_range {
            for key in low..high+1 {
                self.elements.insert(key, true);
            }
            return Some(low..high+1);
        } else {
            return None;
        }
    }
}
