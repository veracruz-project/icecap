use crate::{sys, Error, LargePage, LocalCPtr, Result, Word, TCB};

pub fn reset_log() -> Result<()> {
    Error::wrap(unsafe { sys::seL4_BenchmarkResetLog() })
}

pub fn finalize_log() -> Word {
    unsafe { sys::seL4_BenchmarkFinalizeLog() }
}

pub fn set_log_buffer(frame: LargePage) -> Result<()> {
    Error::wrap(unsafe { sys::seL4_BenchmarkSetLogBuffer(frame.raw()) })
}

pub fn get_thread_utilisation(tcb: TCB) {
    unsafe { sys::seL4_BenchmarkGetThreadUtilisation(tcb.raw()) }
}

pub fn reset_thread_utilisation(tcb: TCB) {
    unsafe { sys::seL4_BenchmarkResetThreadUtilisation(tcb.raw()) }
}

pub fn dump_all_thread_utilisation() {
    unsafe { sys::seL4_BenchmarkDumpAllThreadsUtilisation() }
}

pub fn reset_all_thread_utilisation() {
    unsafe { sys::seL4_BenchmarkResetAllThreadsUtilisation() }
}
