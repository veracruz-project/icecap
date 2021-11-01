/* This file is derived from
 * https://github.com/seL4/seL4_libs/blob/master/libsel4utils/include/sel4utils/sel4_zf_logif.h
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

#include <capdl_loader_app/shim/zf_log.h>
#include <capdl_loader_app/shim/strerror.h>

/*  sel4_zf_logif.h:
 * This file contains some convenience macros built on top of the ZF_LOG
 * library, to reduce source size and improve single-line readability.
 *
 * ZF_LOG?_IF(condition, fmt, ...):
 *  These will call the relevant ZF_LOG?() macro if "condition" evaluates to
 *  true at runtime.
 *
 */

#define ZF_LOGD_IFERR(err, fmt, ...) \
	if ((err) != seL4_NoError) \
		{ ZF_LOGD("[Err %s]:\n\t" fmt, sel4_strerror(err), ## __VA_ARGS__); }

#define ZF_LOGI_IFERR(err, fmt, ...) \
	if ((err) != seL4_NoError) \
		{ ZF_LOGI("[Err %s]:\n\t" fmt, sel4_strerror(err), ## __VA_ARGS__); }

#define ZF_LOGW_IFERR(err, fmt, ...) \
	if ((err) != seL4_NoError) \
		{ ZF_LOGW("[Err %s]:\n\t" fmt, sel4_strerror(err), ## __VA_ARGS__); }

#define ZF_LOGE_IFERR(err, fmt, ...) \
	if ((err) != seL4_NoError) \
		{ ZF_LOGE("[Err %s]:\n\t" fmt, sel4_strerror(err), ## __VA_ARGS__); }

#define ZF_LOGF_IFERR(err, fmt, ...) \
	if ((err) != seL4_NoError) \
		{ ZF_LOGF("[Err %s]:\n\t" fmt, sel4_strerror(err), ## __VA_ARGS__); }
