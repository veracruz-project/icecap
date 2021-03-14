use alloc::vec::Vec;
use crate::EhRef;

extern "C" {
    static icecap_runtime_text_start: usize;
    static icecap_runtime_text_end: usize;
    static icecap_runtime_eh_frame_hdr_start: usize;
    static icecap_runtime_eh_frame_hdr_end: usize;
    static icecap_runtime_eh_frame_end: usize;
}

pub(crate) fn find_cfi_sections() -> Vec<EhRef> {
    vec![
        unsafe {
            EhRef {
                text: (icecap_runtime_text_start..icecap_runtime_text_end),
                eh_frame_hdr: (icecap_runtime_eh_frame_hdr_start..icecap_runtime_eh_frame_hdr_end),
                eh_frame_end: icecap_runtime_eh_frame_end,
            }
        }
    ]
}
