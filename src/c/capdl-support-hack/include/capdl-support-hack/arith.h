/* This file is derived from
 * https://github.com/seL4/util_libs/blob/master/libutils/include/utils/arith.h
 *
 * Copyright (c) 2017 Data61, CSIRO (ABN 41 687 119 230). All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#pragma once

#define BIT(n) (1ul<<(n))

#define MASK_UNSAFE(x) ((BIT(x) - 1ul))

/* The MASK_UNSAFE operation involves using BIT that performs a left shift, this
 * shift is only defined by the C standard if shifting by 1 less than the
 * number of bits in a word. MASK allows both the safe creation of masks, and for
 * creating masks that are larger than what is possible with MASK_UNSAFE, as
 * MASK_UNSAFE cannot create a MASK that is all 1's */
#define MASK(n) \
    ({  typeof (n) _n = (n); \
        (void)assert(_n <= (sizeof(unsigned long) * 8)); \
        (void)assert(_n > 0); \
        MASK_UNSAFE(_n - 1) | BIT(_n - 1); \
    })

#define ROUND_UP(n, b) \
    ({ typeof (n) _n = (n); \
       typeof (b) _b = (b); \
       (_n + (_n % _b == 0 ? 0 : (_b - (_n % _b)))); \
    })

#define MIN(a,b) \
    ({ typeof (a) _a = (a); \
       typeof (b) _b = (b); \
       _a < _b ? _a : _b; })
