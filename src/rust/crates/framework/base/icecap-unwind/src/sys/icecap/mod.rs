use alloc::vec::Vec;
use crate::EhRef;

pub(crate) fn find_cfi_sections() -> Vec<EhRef> {
    vec![
        EhRef {
            // TODO
            text: 0..0,
            eh_frame_hdr: 0..0,
            eh_frame_end: 0,
        }
    ]
}
