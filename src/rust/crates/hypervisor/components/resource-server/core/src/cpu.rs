use icecap_core::prelude::*;

pub const NUM_NODES: usize = icecap_plat::NUM_CORES - 1;

pub fn schedule(tcb: TCB, node: Option<usize>) -> sel4::Result<()> {
    tcb.set_affinity(node.unwrap_or(NUM_NODES) as u64)
}
