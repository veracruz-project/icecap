use core::time::Duration;

static mut NOW: Duration = Duration::from_secs(0);

pub fn now() -> Duration {
    unsafe { NOW }
}

pub fn set_now(now: Duration) {
    unsafe {
        NOW = now;
    }
}
