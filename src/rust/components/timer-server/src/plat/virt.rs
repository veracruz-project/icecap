use crate::device::QemuTimerDevice;

pub fn timer_device(base_addr: usize) -> QemuTimerDevice {
    QemuTimerDevice::new(base_addr)
}
