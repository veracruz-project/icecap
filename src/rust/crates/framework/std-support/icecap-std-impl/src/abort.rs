pub unsafe fn abort() -> ! {
    crate::runtime::stop_component()
}
