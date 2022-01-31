#pragma once

#include <sel4/sel4.h>
#include <icecap-runtime/config.h>

#define ICECAP_NORETURN __attribute__((__noreturn__))

// == entry ==

// thread start protocol:
// - sp: set
// - x0: struct icecap_runtime_config *config
// - x1: seL4_Word thread_index

struct icecap_runtime_heap_info {
    seL4_Word start;
    seL4_Word end;
    seL4_CPtr lock;
};

struct icecap_runtime_tls_image {
    seL4_Word vaddr;
    seL4_Word filesz;
    seL4_Word memsz;
    seL4_Word align;
};

struct icecap_runtime_arg {
    seL4_Word offset; // offset from &config
    seL4_Word size;
};

struct icecap_runtime_thread_config {
    seL4_IPCBuffer *ipc_buffer;
    seL4_CPtr endpoint;
    seL4_CPtr tcb;
};

struct icecap_runtime_config {
    struct icecap_runtime_heap_info heap_info;
    struct icecap_runtime_tls_image tls_image;
    struct icecap_runtime_arg arg;
    seL4_Word image_path_offset;
    seL4_CPtr print_lock;
    seL4_CPtr idle_notification;
    seL4_Uint64 num_threads;
    struct icecap_runtime_thread_config threads[];
};

void ICECAP_NORETURN __icecap_runtime_start(struct icecap_runtime_config *config, seL4_Word thread_index);

// == calls from runtime ==

void icecap_main(void *arg, seL4_Word arg_size);

typedef void (*icecap_runtime_secondary_thread_entry_fn)(seL4_Word arg0, seL4_Word arg1);

// == calls into runtime ==

extern seL4_Word icecap_runtime_heap_start;
extern seL4_Word icecap_runtime_heap_end;
extern seL4_CPtr icecap_runtime_heap_lock;

extern const char *icecap_runtime_image_path;

extern seL4_Word icecap_runtime_tls_region_align;
extern seL4_Word icecap_runtime_tls_region_size;

extern seL4_CPtr icecap_runtime_print_lock;
extern seL4_CPtr icecap_runtime_idle_notification;
extern __thread seL4_CPtr icecap_runtime_tcb;

// returns TPIDR
seL4_Word icecap_runtime_tls_region_init(void *region);

void icecap_runtime_tls_region_insert(
    void *dst_tls_region,
    void *local_ptr, // & of __thread variable
    void *src,
    seL4_Word n
    );

void icecap_runtime_tls_region_insert_ipc_buffer(void *dst_tls_region, void *ipc_buffer);
void icecap_runtime_tls_region_insert_tcb(void *dst_tls_region, seL4_CPtr tcb);

void ICECAP_NORETURN icecap_runtime_stop_thread(void);
void ICECAP_NORETURN icecap_runtime_stop_component(void);

// TODO

// Support some kind of early initialization hook and/or constructors.  This
// would enable extensibility. For example, it would allow early Rust code to
// depend on component-specific symbols which themselves require early
// initialization.  This extension mechanism would replace older hacks such as
// 'icecap_runtime_supervisor_ep' and 'icecap_runtime_fault_handling'.

// This early initialization hook should allow initialization routines to shrink
// the arg. An routine might use some of the arg for itself and then pass the
// rest on.  This hook should also allow routines to hook into other parts of
// the C runtime, such as exiting and fault handling.
