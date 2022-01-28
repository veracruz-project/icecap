#[cfg(target_os = "icecap")]
mod icecap;

#[cfg(target_os = "icecap")]
pub(crate) use icecap::find_cfi_sections;
