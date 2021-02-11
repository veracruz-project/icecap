#include <icecap_runtime.h>
#include <icecap_utils/printf.h>
#include <icecap_utils/assert.h>

void __icecap_utils_assert_fail(const char *expr, const char *file, int line, const char *func)
{
    icecap_utils_debug_printf("__assert_fail(\"%s\", %s, %d, %s)\n");
    icecap_runtime_exit();
}
