/* This file is derived from
 * https://github.com/seL4/util_libs/blob/master/libutils/include/utils/zf_log.h
 *
 * Copyright (c) 2017 wonder-mice
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#pragma once

#include <icecap_utils.h>

#define ZF_show(...) do { \
    icecap_utils_debug_printf("%s:%d ", __func__, __LINE__); \
    icecap_utils_debug_printf(__VA_ARGS__); \
    icecap_utils_debug_printf("\n"); \
} while (0)

#define ZF_LOGV(...) // ZF_show(__VA_ARGS__)
#define ZF_LOGD(...) // ZF_show(__VA_ARGS__)
#define ZF_LOGI(...) ZF_show(__VA_ARGS__)
#define ZF_LOGW(...) ZF_show(__VA_ARGS__)
#define ZF_LOGE(...) ZF_show(__VA_ARGS__)
#define ZF_LOGF(...) ZF_show(__VA_ARGS__)
