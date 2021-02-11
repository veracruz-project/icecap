#include <icecap_runtime/config.h>

.section .text

#ifdef ICECAP_RUNTIME_ROOT

.extern __icecap_runtime_root_start

.global _start
_start:
    ldr x19, =__icecap_runtime_root_stack_top
    add sp, x19, #0
    b __icecap_runtime_root_start

.section .bss
__icecap_runtime_root_stack_base:
    .align 16
    .space ICECAP_RUNTIME_ROOT_STACK_SIZE
__icecap_runtime_root_stack_top:

#else

.extern __icecap_runtime_start

.global _start
_start:
    b __icecap_runtime_start

#endif
