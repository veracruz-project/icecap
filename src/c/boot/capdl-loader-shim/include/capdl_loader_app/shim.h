#pragma once

#include <capdl_loader_app/shim/arith.h>
#include <capdl_loader_app/shim/ansi.h>
#include <capdl_loader_app/shim/config.h>

#include <capdl_loader_app/shim/page.h>
#include <capdl_loader_app/shim/kobject_t_arch.h>
#include <capdl_loader_app/shim/kobject_t.h>
#include <capdl_loader_app/shim/kobject_t_sel4_arch.h>

#include <capdl_loader_app/shim/zf_log.h>
#include <capdl_loader_app/shim/zf_log_if.h>
#include <capdl_loader_app/shim/strerror.h>
#include <capdl_loader_app/shim/sel4_zf_logif.h>

#define PACKED __attribute__((__packed__))
#define UNUSED __attribute__((__unused__))

#define PAGE_SIZE_4K 4096

typedef signed long ssize_t;
