#include <sel4/sel4.h>
#include <icecap_utils.h>

void icecap_main(void *arg, seL4_Word arg_size)
{
    icecap_utils_debug_printf("Hello, World!\n");
}
