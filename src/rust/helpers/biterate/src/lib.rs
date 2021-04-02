#![no_std]

#![feature(type_ascription)]

use num::{PrimInt, One};

pub fn biterate<T: PrimInt + One>(set: T) -> Biterator<T> {
    Biterator(set)
}

pub struct Biterator<T>(T);

impl<T: PrimInt + One> Iterator for Biterator<T> {
    type Item = u32;

    fn next(&mut self) -> Option<Self::Item> {
        if self.0.is_zero() {
            None
        } else {
            let r = self.0.trailing_zeros();
            self.0 = self.0 ^ (One::one(): T).unsigned_shl(r);
            Some(r)
        }
    }
}
