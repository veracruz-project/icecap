pub fn read_cntfrq_el0() -> u32 {
    unsafe {
        let mut r: u32;
        llvm_asm!("mrs $0, cntfrq_el0" : "=r"(r));
        r
    }
}

pub fn read_cntvct_el0() -> u64 {
    unsafe {
        let mut r: u64;
        llvm_asm!("mrs $0, cntvct_el0" : "=r"(r));
        r
    }
}
