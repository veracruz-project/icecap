#pragma once

#define assert(expr) ((void)((expr) || (__assert_fail(#expr, __FILE__, __LINE__, __func__),0)))

void __assert_fail(const char *, const char *, int, const char *);
