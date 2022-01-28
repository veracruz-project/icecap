pub use icecap_core::prelude::*;

// 'Thread' would conflict with libstd, and is thus unsuitable for icecap_core::prelude
pub use icecap_core::runtime::Thread;

pub use icecap_core::logger;

pub use crate::{print, println};
