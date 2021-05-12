pub unsafe fn abort() -> ! {
    crate::runtime::exit()
}
