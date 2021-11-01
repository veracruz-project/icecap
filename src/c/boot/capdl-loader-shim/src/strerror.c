/* This file is derived from
 * https://github.com/seL4/seL4_libs/blob/master/libsel4utils/src/strerror.c
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

#include <capdl_loader_app/shim/zf_log.h>
#include <assert.h>
#include <stddef.h>
#include <sel4/sel4.h>
#include <capdl_loader_app/shim/strerror.h>

#define _PRIV_SEL4_FAULTLIST_UNKNOWN_IDX (seL4_Fault_UserException + 1)
#ifdef CONFIG_ARM_HYPERVISOR_SUPPORT
#define _PRIV_SEL4_FAULTLIST_MAX_IDX     (seL4_Fault_VCPUFault)
#else
#define _PRIV_SEL4_FAULTLIST_MAX_IDX     (seL4_Fault_VMFault)
#endif

char *sel4_errlist[] = {
    [seL4_NoError] = "seL4_NoError",
    [seL4_InvalidArgument] = "seL4_InvalidArgument",
    [seL4_InvalidCapability] = "seL4_InvalidCapability",
    [seL4_IllegalOperation] = "seL4_IllegalOperation",
    [seL4_RangeError] = "seL4_RangeError",
    [seL4_AlignmentError] = "seL4_AlignmentError",
    [seL4_FailedLookup] = "seL4_FailedLookup",
    [seL4_TruncatedMessage] = "seL4_TruncatedMessage",
    [seL4_DeleteFirst] = "seL4_DeleteFirst",
    [seL4_RevokeFirst] = "seL4_RevokeFirst",
    [seL4_NotEnoughMemory] = "seL4_NotEnoughMemory",
    NULL
};

char *sel4_faultlist[] = {
    [seL4_Fault_NullFault] = "seL4_Fault_NullFault",
    [seL4_Fault_CapFault] = "seL4_Fault_CapFault",
    [seL4_Fault_UnknownSyscall] = "seL4_Fault_UnknownSyscall",
    [seL4_Fault_UserException] = "seL4_Fault_UserException",
    [_PRIV_SEL4_FAULTLIST_UNKNOWN_IDX] = "Unknown Fault",
    [seL4_Fault_VMFault] = "seL4_Fault_VMFault",
#ifdef CONFIG_ARM_HYPERVISOR_SUPPORT
    [seL4_Fault_VGICMaintenance] = "seL4_Fault_VGICMaintenance",
    [seL4_Fault_VCPUFault] = "seL4_Fault_VCPUFault"
#endif
};

const char *
sel4_strerror(int errcode)
{
    assert(errcode < sizeof(sel4_errlist) / sizeof(*sel4_errlist) - 1);
    return sel4_errlist[errcode];
}

void
__sel4_error(int sel4_error, const char *file,
             const char *function, int line, char * str)
{
    ZF_LOGE("seL4 Error: %s, function %s, file %s, line %d: %s\n",
            sel4_errlist[sel4_error],
            function, file, line, str);
}

const char *
sel4_strfault(int faultlabel)
{
    if (faultlabel > _PRIV_SEL4_FAULTLIST_MAX_IDX || faultlabel == _PRIV_SEL4_FAULTLIST_UNKNOWN_IDX
	|| faultlabel < seL4_Fault_NullFault) {
        return sel4_faultlist[_PRIV_SEL4_FAULTLIST_UNKNOWN_IDX];
    }

    return sel4_faultlist[faultlabel];
}
