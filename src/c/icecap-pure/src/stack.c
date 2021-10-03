#include <stddef.h>

// TODO init at boot
#define STACK_CHK_GUARD 0x595e9fbd94fda766

uintptr_t __stack_chk_guard = STACK_CHK_GUARD;

__attribute__((noreturn))
void __stack_chk_fail(void)
{
    int __attribute__((unused)) x = *(int *)1243;
    __builtin_unreachable();
}
