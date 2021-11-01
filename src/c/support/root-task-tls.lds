SECTIONS
{
    .tdata :
    {
        __icecap_runtime_root_tdata_start = . ;
        *(.tdata .tdata.* .gnu.linkonce.td.*)
        __icecap_runtime_root_tdata_end = . ;
    }
    .tbss :
    {
        __icecap_runtime_root_tbss_start = . ;
        *(.tbss .tbss.* .gnu.linkonce.tb.*) *(.tcommon)
        __icecap_runtime_root_tbss_end = . ;
    }
}
INSERT AFTER .rodata;
