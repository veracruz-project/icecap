/* This file is derived from
 * https://github.com/seL4/util_libs/blob/master/libutils/include/utils/zf_log_if.h
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

#include <capdl-support-hack/zf_log.h>

/*  zf_logif.h:
 * This file contains some convenience macros built on top of the ZF_LOG
 * library, to reduce source size and improve single-line readability.
 *
 * ZF_LOG?_IF(condition, fmt, ...):
 *  These will call the relevant ZF_LOG?() macro if "condition" evaluates to
 *  true at runtime.
 *
 */

#define ZF_LOGD_IF(cond, fmt, ...) \
	if (cond) { ZF_LOGD("[Cond failed: %s]\n\t" fmt, #cond, ## __VA_ARGS__); }
#define ZF_LOGI_IF(cond, fmt, ...) \
	if (cond) { ZF_LOGI("[Cond failed: %s]\n\t" fmt, #cond, ## __VA_ARGS__); }
#define ZF_LOGW_IF(cond, fmt, ...) \
	if (cond) { ZF_LOGW("[Cond failed: %s]\n\t" fmt, #cond, ## __VA_ARGS__); }
#define ZF_LOGE_IF(cond, fmt, ...) \
	if (cond) { ZF_LOGE("[Cond failed: %s]\n\t" fmt, #cond, ## __VA_ARGS__); }
#define ZF_LOGF_IF(cond, fmt, ...) \
	if (cond) { ZF_LOGF("[Cond failed: %s]\n\t" fmt, #cond, ## __VA_ARGS__); }
