#[cfg(target_os = "icecap")]
pub mod icecap;

#[cfg(target_os = "icecap")]
pub(crate) use icecap::{
    find_cfi_sections,
};
