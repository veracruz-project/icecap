#![no_std]

use icecap_sel4::prelude::*;
use icecap_sel4::fault::VMFault;
use icecap_failure::Fallible;
use icecap_vmm_gic::{GIC, GICCallbacks};

// TODO enrich

// NOTE value shared with Linux kernel
pub const SYS_PUTCHAR: u64 = 1337;

pub fn offset_in_region(addr: usize, region_start: usize, region_size: usize) -> Option<usize> {
    if region_start <= addr && addr < region_start + region_size {
        Some(addr - region_start)
    } else {
        None
    }
}

pub fn handle_gic_distributor_fault<T: GICCallbacks>(gic: &mut GIC<T>, node_index: usize, tcb: TCB, fault: VMFault, offset: usize) -> Fallible<()> {
    assert!(fault.is_valid());
    assert!(fault.is_aligned());
    if fault.is_write() {
        let mut ctx = tcb.read_all_registers(false).unwrap();
        let data = fault.data(&ctx);
        gic.handle_write(node_index, offset, data)?;
        ctx.advance();
        tcb.write_all_registers(false, &mut ctx).unwrap();
    } else if fault.is_read() {
        let data = gic.handle_read(node_index, offset, fault.width())?;
        let mut ctx = tcb.read_all_registers(false).unwrap();
        fault.emulate_read(&mut ctx, data);
        ctx.advance();
        tcb.write_all_registers(false, &mut ctx).unwrap();
    } else {
        panic!();
    }
    Ok(())
}
