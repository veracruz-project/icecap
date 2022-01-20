#pragma once

// This file assumes "LP64" and char unsigned.

#define CHAR_BIT 8

#define SCHAR_MAX 0x7f
#define SCHAR_MIN (-SCHAR_MAX - 1)
#define UCHAR_MAX (SCHAR_MAX * 2 + 1)
#define CHAR_MIN 0
#define CHAR_MAX UCHAR_MAX

#define SHRT_MAX 0x7fff
#define SHRT_MIN (-SHRT_MAX - 1)
#define USHRT_MAX (SHRT_MAX * 2 + 1)

#define INT_MAX 0x7fffffff
#define INT_MIN (-INT_MAX - 1)
#define UINT_MAX (INT_MAX * 2U + 1U)

#define LONG_MAX 0x7fffffffffffffffL
#define LONG_MIN (-LONG_MAX - 1L)
#define ULONG_MAX (LONG_MAX * 2UL + 1UL)

#define LLONG_MAX 0x7fffffffffffffffLL
#define LLONG_MIN (-LLONG_MAX - 1LL)
#define ULLONG_MAX (LLONG_MAX * 2ULL + 1ULL)

#define SSIZE_MAX LONG_MAX
