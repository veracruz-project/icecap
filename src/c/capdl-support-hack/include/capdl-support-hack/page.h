/* This file is derived from
 * https://github.com/seL4/seL4_libs/blob/master/libsel4vspace/arch_include/arm/vspace/arch/page.h
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

#include <sel4/sel4.h>

#define seL4_ARCH_Uncached_VMAttributes 0

#define seL4_ARCH_Page_Map             seL4_ARM_Page_Map
#define seL4_ARCH_Page_MapIO           seL4_ARM_Page_MapIO
#define seL4_ARCH_Page_Unmap           seL4_ARM_Page_Unmap
#define seL4_ARCH_Page_GetAddress      seL4_ARM_Page_GetAddress
#define seL4_ARCH_Page_GetAddress_t    seL4_ARM_Page_GetAddress_t
#define seL4_ARCH_PageTable_Map        seL4_ARM_PageTable_Map
#define seL4_ARCH_IOPageTable_Map      seL4_ARM_IOPageTable_Map
#define seL4_ARCH_PageTable_Unmap      seL4_ARM_PageTable_Unmap
#define seL4_ARCH_ASIDPool_Assign      seL4_ARM_ASIDPool_Assign
#define seL4_ARCH_ASIDControl_MakePool seL4_ARM_ASIDControl_MakePool
#define seL4_ARCH_PageTableObject      seL4_ARM_PageTableObject
#define seL4_ARCH_PageDirectoryObject  seL4_ARM_PageDirectoryObject
#define seL4_ARCH_Default_VMAttributes seL4_ARM_Default_VMAttributes
#define seL4_ARCH_VMAttributes         seL4_ARM_VMAttributes
#define seL4_ARCH_4KPage               seL4_ARM_SmallPageObject
#define seL4_ARCH_LargePageObject      seL4_ARM_LargePageObject
/* for the size of a large page use seL4_LargePageBits */
#define ARCHPageGetAddress             ARMPageGetAddress
