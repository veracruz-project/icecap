#[allow(deprecated)]
fn read_cntfrq_el0() -> u32 {
    unsafe {
        let mut r: u32;
        llvm_asm!("mrs $0, cntfrq_el0" : "=r"(r));
        r
    }
}

#[allow(deprecated)]
fn read_cntvct_el0() -> u64 {
    unsafe {
        let mut r: u64;
        llvm_asm!("mrs $0, cntvct_el0" : "=r"(r));
        r
    }
}

pub fn time_ns() -> u64 {
    let cntfrq = read_cntfrq_el0() as i128;
    let cntvct = read_cntvct_el0() as i128;
    ((cntvct * 1_000_000_000) / cntfrq) as u64
}
