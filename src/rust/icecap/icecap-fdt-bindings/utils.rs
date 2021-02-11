use core::ops::{Add, Range};

pub fn mk_range<Idx: Copy + Add<Output = Idx>>(start: Idx, size: Idx) -> Range<Idx> {
    start .. start + size
}
