mod virt;
mod rpi4;

#[cfg(icecap_plat = "virt")]
use virt as plat_impl;
#[cfg(icecap_plat = "rpi4")]
use rpi4 as plat_impl;

pub use plat_impl::*;
