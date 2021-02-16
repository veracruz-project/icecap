extern "C" {
    fn icecap_runtime_exit() -> !;
}

pub unsafe fn abort() -> ! {
    icecap_runtime_exit()
}
