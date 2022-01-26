use core::ops::Range;
use core::slice;
use core::str;

use crate::c;

pub fn image_path() -> Result<&'static str, str::Utf8Error> {
    str::from_utf8({
        let start = unsafe { c::icecap_runtime_image_path };
        let mut size = 0;
        loop {
            match unsafe { *start.offset(size as isize) } {
                0 => break,
                _ => size += 1,
            }
        }
        unsafe { slice::from_raw_parts(start, size) }
    })
}

pub fn text() -> Range<usize> {
    unsafe { c::icecap_runtime_text_start..c::icecap_runtime_text_end }
}
pub fn eh_frame_hdr() -> Range<usize> {
    unsafe { c::icecap_runtime_eh_frame_hdr_start..c::icecap_runtime_eh_frame_hdr_end }
}

pub fn eh_frame_end() -> usize {
    unsafe { c::icecap_runtime_eh_frame_end }
}
