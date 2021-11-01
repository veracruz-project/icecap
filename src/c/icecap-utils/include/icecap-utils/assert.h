#pragma once

#define icecap_utils_assert(expr) ((void)((expr) || (__icecap_utils_assert_fail(#expr, __FILE__, __LINE__, __func__),0)))

void __icecap_utils_assert_fail(const char *expr, const char *file, int line, const char *func);
