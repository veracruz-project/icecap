#pragma once

#include <capdl-support-hack/arith.h>
#include <capdl-support-hack/ansi.h>
#include <capdl-support-hack/config.h>

#include <capdl-support-hack/page.h>
#include <capdl-support-hack/kobject_t_arch.h>
#include <capdl-support-hack/kobject_t.h>
#include <capdl-support-hack/kobject_t_sel4_arch.h>

#include <capdl-support-hack/zf_log.h>
#include <capdl-support-hack/zf_log_if.h>
#include <capdl-support-hack/strerror.h>
#include <capdl-support-hack/sel4_zf_logif.h>

#define PACKED __attribute__((__packed__))
#define UNUSED __attribute__((__unused__))

#define PAGE_SIZE_4K 4096
