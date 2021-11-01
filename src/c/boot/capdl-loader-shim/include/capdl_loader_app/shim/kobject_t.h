/* This file is derived from
 * https://github.com/seL4/seL4_libs/blob/master/libsel4vka/include/vka/kobject_t.h
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

#include <sel4/types.h>
#include <assert.h>
#include <autoconf.h>
#include <capdl_loader_app/shim/kobject_t_arch.h>

/* Generic Kernel Object Type used by generic allocator */

enum _kobject_type {
    KOBJECT_TCB = KOBJECT_ARCH_NUM_TYPES,
    KOBJECT_CNODE,
    KOBJECT_CSLOT,
    KOBJECT_UNTYPED,
    KOBJECT_ENDPOINT,
    KOBJECT_NOTIFICATION,
    KOBJECT_REPLY,
    KOBJECT_SCHED_CONTEXT,
#ifdef CONFIG_CACHE_COLORING
    KOBJECT_KERNEL_IMAGE,
#endif
    NUM_KOBJECT_TYPES

};
/*
 * Get the size (in bits) of the untyped memory required to
 * create an object of the given size.
 */
static inline seL4_Word kobject_get_size(kobject_t type, seL4_Word objectSize)
{
    switch (type) {
    /* Generic objects. */
    case KOBJECT_TCB:
        return seL4_TCBBits;
    case KOBJECT_CNODE:
        return (seL4_SlotBits + objectSize);
    case KOBJECT_CSLOT:
        return 0;
    case KOBJECT_UNTYPED:
        return objectSize;
    case KOBJECT_ENDPOINT:
        return seL4_EndpointBits;
    case KOBJECT_NOTIFICATION:
        return seL4_EndpointBits;
    case KOBJECT_PAGE_DIRECTORY:
        return seL4_PageDirBits;
    case KOBJECT_PAGE_TABLE:
        return seL4_PageTableBits;
#ifdef CONFIG_KERNEL_MCS
    case KOBJECT_REPLY:
        return seL4_ReplyBits;
    case KOBJECT_SCHED_CONTEXT:
        return objectSize > seL4_MinSchedContextBits ? objectSize : seL4_MinSchedContextBits;
#endif
#ifdef CONFIG_CACHE_COLORING
    case KOBJECT_KERNEL_IMAGE:
        return seL4_KernelImageBits;
#endif
    default:
        return arch_kobject_get_size(type, objectSize);
    }
}

static inline seL4_Word kobject_get_type(kobject_t type, seL4_Word objectSize)
{
    switch (type) {
    /* Generic objects. */
    case KOBJECT_TCB:
        return seL4_TCBObject;
    case KOBJECT_CNODE:
        return seL4_CapTableObject;
    case KOBJECT_CSLOT:
        return -1;
    case KOBJECT_UNTYPED:
        return seL4_UntypedObject;
    case KOBJECT_ENDPOINT:
        return seL4_EndpointObject;
    case KOBJECT_NOTIFICATION:
        return seL4_NotificationObject;
#ifdef CONFIG_KERNEL_MCS
    case KOBJECT_SCHED_CONTEXT:
        return seL4_SchedContextObject;
    case KOBJECT_REPLY:
        return seL4_ReplyObject;
#endif
#ifdef CONFIG_CACHE_COLORING
    case KOBJECT_KERNEL_IMAGE:
        return seL4_KernelImageObject;
#endif
    default:
        return arch_kobject_get_type(type, objectSize);
    }
}
