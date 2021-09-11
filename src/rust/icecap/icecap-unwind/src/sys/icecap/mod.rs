use alloc::vec::Vec;
use icecap_runtime::{text, eh_frame_hdr, eh_frame_end};
use crate::EhRef;

pub(crate) fn find_cfi_sections() -> Vec<EhRef> {
    vec![
        EhRef {
            text: text(),
            eh_frame_hdr: eh_frame_hdr(),
            eh_frame_end: eh_frame_end(),
        }
    ]
}
