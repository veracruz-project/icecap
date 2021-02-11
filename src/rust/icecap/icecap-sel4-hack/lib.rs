#![no_std]

#[cfg(target_os = "icecap")]
pub use icecap_sel4 as sel4;

#[cfg(target_os = "icecap")]
pub mod prelude {
    pub use super::sel4::prelude::*;
    pub use icecap_runtime::Thread;
}

#[cfg(not(target_os = "icecap"))]
pub use icecap_sel4_hack_meta::*;
