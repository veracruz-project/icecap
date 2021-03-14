use core::{char, cell, num, fmt, array};
use core::alloc::{AllocErr, LayoutErr};
use alloc::{str, string};

use icecap_sel4 as sel4;

use crate::Fail;

impl Fail for sel4::Error {}

// HACK trivial impls to match std/error.rs

impl Fail for ! {}

impl Fail for AllocErr {}

impl Fail for LayoutErr {}

impl Fail for str::ParseBoolError {}

impl Fail for str::Utf8Error {}

impl Fail for num::ParseIntError {}

impl Fail for num::TryFromIntError {}

impl Fail for array::TryFromSliceError {}

impl Fail for num::ParseFloatError {}

impl Fail for string::FromUtf8Error {}

impl Fail for string::FromUtf16Error {}

impl Fail for string::ParseError {}

impl Fail for char::DecodeUtf16Error {}

impl Fail for fmt::Error {}

impl Fail for cell::BorrowError {}

impl Fail for cell::BorrowMutError {}

impl Fail for char::CharTryFromError {}

impl Fail for char::ParseCharError {}
