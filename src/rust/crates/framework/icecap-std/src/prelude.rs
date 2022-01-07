pub use icecap_core::prelude::*;

// Re-exports that would conflict with libstd, and are thus unsuitable for icecap-core
pub use icecap_core::runtime::Thread;

pub use crate::{logger, print, println};
