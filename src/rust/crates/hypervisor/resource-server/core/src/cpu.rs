use icecap_core::prelude::*;

pub const NUM_ACTIVE_CORES: usize = icecap_plat::NUM_CORES - 1;

pub fn schedule(tcb: TCB, node: Option<usize>) -> sel4::Result<()> {
    tcb.set_affinity(node.unwrap_or(NUM_ACTIVE_CORES) as u64)
}
