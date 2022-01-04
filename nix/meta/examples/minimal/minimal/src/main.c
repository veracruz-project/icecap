#include <sel4/sel4.h>

void icecap_main(void *config, seL4_Uint64 size)
{
    for (int i = 0; i < size; i++) {
        seL4_DebugPutChar(((char *)config)[i]);
    }
}
