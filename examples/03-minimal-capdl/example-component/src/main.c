#include <sel4/sel4.h>
#include <icecap-utils.h>

void icecap_main(void *config, seL4_Uint64 size)
{
    icecap_utils_debug_printf("config:\n");
    for (int i = 0; i < size; i++) {
        seL4_DebugPutChar(((char *)config)[i]);
    }
}
