extern "C" {

    #[thread_local]
    pub(crate) static icecap_runtime_tcb: u64;

    pub(crate) fn icecap_runtime_exit() -> !;

    pub(crate) static icecap_runtime_tls_region_align: usize;
    pub(crate) static icecap_runtime_tls_region_size: usize;
    pub(crate) fn icecap_runtime_tls_region_init(tls_region: usize) -> u64;
    pub(crate) fn icecap_runtime_tls_region_insert_ipc_buffer(dst_tls_region: usize, ipc_buffer: usize);
    pub(crate) fn icecap_runtime_tls_region_insert_tcb(dst_tls_region: usize, tcb: u64);

    pub(crate) static icecap_runtime_image_path: *const u8;
    pub(crate) static icecap_runtime_text_start: usize;
    pub(crate) static icecap_runtime_text_end: usize;
    pub(crate) static icecap_runtime_eh_frame_hdr_start: usize;
    pub(crate) static icecap_runtime_eh_frame_hdr_end: usize;
    pub(crate) static icecap_runtime_eh_frame_end: usize;

    pub(crate) static icecap_runtime_supervisor_endpoint: u64;

}
