SECTIONS {
    _tdata_start = ADDR(.tdata);
    _tdata_end = ADDR(.tdata) + SIZEOF(.tdata);
    _tbss_start = ADDR(.tbss);
    _tbss_end = ADDR(.tbss) + SIZEOF(.tbss);
}
INSERT AFTER .rodata;
