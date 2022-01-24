#pragma once

#include <stdint.h>

#define _JBLEN 22

typedef uint64_t jmp_buf[_JBLEN];

void longjmp(jmp_buf env, int val);
int setjmp(jmp_buf env);
