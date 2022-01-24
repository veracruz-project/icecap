#include <icecap-runtime.h>
#include <stdint.h>

// TODO should this be in icecap-runtime?

// TODO init at boot
#define STACK_CHK_GUARD 0x595e9fbd94fda766

uintptr_t __stack_chk_guard = STACK_CHK_GUARD;

__attribute__((noreturn))
void __stack_chk_fail(void)
{
    icecap_runtime_stop_component();
}
