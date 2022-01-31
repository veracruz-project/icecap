use core::ops::Range;
use core::slice;
use core::str;

use crate::c;

pub fn image_path() -> Option<Result<&'static str, str::Utf8Error>> {
    let start = unsafe { c::icecap_runtime_image_path };
    if start.is_null() {
        None
    } else {
        Some({
            let mut size = 0;
            loop {
                match unsafe { *start.offset(size as isize) } {
                    0 => break,
                    _ => size += 1,
                }
            }
            str::from_utf8(unsafe { slice::from_raw_parts(start, size) })
        })
    }
}

pub fn text() -> Range<usize> {
    0..0
}

pub fn eh_frame_hdr() -> Range<usize> {
    0..0
}

pub fn eh_frame() -> Range<usize> {
    0..0
}
