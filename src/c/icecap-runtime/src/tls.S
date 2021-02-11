.section .text

.extern __icecap_runtime_continue

.global __icecap_runtime_reserve_tls
__icecap_runtime_reserve_tls:
    orr x3, x3, #0xff // alignment (max of tls region and stack alignments)
    mvn x3, x3
    sub x2, sp, x2
    and x2, x2, x3
    mov sp, x2
    b __icecap_runtime_continue
