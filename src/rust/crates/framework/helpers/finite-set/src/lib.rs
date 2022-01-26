#![no_std]

pub use finite_set_derive::Finite;

pub trait Finite {
    const CARDINALITY: usize;

    fn to_nat(&self) -> usize;

    // precondition: assert!(n < Self::CARDINALITY)
    fn from_nat(n: usize) -> Self;
}

// HACK
pub fn test_exhaustively_and_slowly<T: Finite + Eq>() {
    for i in 0..T::CARDINALITY {
        let x = T::from_nat(i);
        assert!(i == x.to_nat());
        for j in 0..i {
            assert!(x != T::from_nat(j));
        }
    }
}

#[cfg(test)]
#[macro_use]
extern crate std;

#[cfg(test)]
mod test {
    use super::*;

    // NOTE
    // cargo rustc -p finite-set --profile=check -- -Z macro-backtrace
    // cargo rustc -p finite-set --profile=check -- -Zunstable-options --pretty=expanded

    #[derive(Debug, Eq, PartialEq, Finite)]
    enum A {
        X,
        Y,
    }

    #[derive(Debug, Eq, PartialEq, Finite)]
    enum B {
        X,
        Y,
        Z,
    }

    #[derive(Debug, Eq, PartialEq, Finite)]
    enum C {
        X(A, B),
        Y { a: A, b: B },
    }

    #[test]
    fn test_all() {
        assert_eq!(C::CARDINALITY, 12);
        test_exhaustively_and_slowly::<C>();

        // for i in 0..C::CARDINALITY {
        //     println!("{}: {:?}", i, C::from_nat(i));
        // }
    }
}
