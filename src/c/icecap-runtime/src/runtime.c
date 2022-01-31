#include <sel4/sel4.h>
#include <icecap-runtime.h>

#define ICECAP_UNUSED __attribute__((unused))
#define ICECAP_UNREACHABLE __builtin_unreachable
#define ICECAP_ROUND_UP(n, b) ((n) + ((n) % (b) == 0 ? 0 : ((b) - ((n) % (b)))))
#define ICECAP_GAP_ABOVE_TPIDR 16

// HACK
__thread __attribute__((weak)) seL4_IPCBuffer *__sel4_ipc_buffer;

seL4_Word icecap_runtime_heap_start;
seL4_Word icecap_runtime_heap_end;
seL4_CPtr icecap_runtime_heap_lock;

const char *icecap_runtime_image_path;

seL4_Word icecap_runtime_tls_region_align;
seL4_Word icecap_runtime_tls_region_size;

seL4_CPtr icecap_runtime_print_lock;
seL4_CPtr icecap_runtime_idle_notification;
__thread seL4_CPtr icecap_runtime_tcb;

static struct icecap_runtime_tls_image __icecap_runtime_tls_image;


// NOTE for now, this is only used by 'icecap_runtime_stop_component' for accessing the list of TCBs.
static struct icecap_runtime_config *__icecap_runtime_config;

void ICECAP_NORETURN __icecap_runtime_reserve_tls(struct icecap_runtime_config *config, seL4_Word thread_index, seL4_Word size, seL4_Word align);

static inline seL4_Word __icecap_runtime_tls_region_align_of(struct icecap_runtime_tls_image *tls_image)
{
    return ICECAP_GAP_ABOVE_TPIDR | tls_image->align;
}

static inline seL4_Word __icecap_runtime_tls_region_size_of(struct icecap_runtime_tls_image *tls_image)
{
    return ICECAP_ROUND_UP(ICECAP_GAP_ABOVE_TPIDR, tls_image->align) + tls_image->memsz;
}

static inline seL4_Word __icecap_runtime_tls_region_init_of(struct icecap_runtime_tls_image *tls_image, void *region)
{
    seL4_Uint8 *base = (seL4_Uint8 *)region + ICECAP_GAP_ABOVE_TPIDR;
    seL4_Word i = 0;
    for (; i < tls_image->filesz; i++) {
        *(base + i) = *((seL4_Uint8 *)tls_image->vaddr + i);
    }
    for (; i < tls_image->memsz; i++) {
        *(base + i) = 0;
    }
    return (seL4_Word)region;
}

static inline void __icecap_runtime_set_tpidr(seL4_Word tpidr)
{
    __asm__ __volatile__ ("msr tpidr_el0, %0" :: "r"(tpidr));
}

static inline seL4_Word __icecap_runtime_get_tpidr(void)
{
    seL4_Word tpidr;
    __asm__ __volatile__ ("mrs %0, tpidr_el0" : "=r"(tpidr));
    return tpidr;
}

void ICECAP_NORETURN __icecap_runtime_start(struct icecap_runtime_config *config, seL4_Word thread_index)
{
    seL4_Word align = __icecap_runtime_tls_region_align_of(&config->tls_image);
    seL4_Word size = __icecap_runtime_tls_region_size_of(&config->tls_image);
    __icecap_runtime_reserve_tls(config, thread_index, size, align);
}

void ICECAP_NORETURN __icecap_runtime_continue(struct icecap_runtime_config *config, seL4_Word thread_index, void *tls_region)
{
    __icecap_runtime_config = config;
    seL4_Word tpidr = __icecap_runtime_tls_region_init_of(&config->tls_image, tls_region);
    __icecap_runtime_set_tpidr(tpidr);
    __sel4_ipc_buffer = config->threads[thread_index].ipc_buffer;
    icecap_runtime_tcb = config->threads[thread_index].tcb;
    if (thread_index == 0) {
        icecap_runtime_heap_start = config->heap_info.start;
        icecap_runtime_heap_end = config->heap_info.end;
        icecap_runtime_heap_lock = config->heap_info.lock;
        icecap_runtime_tls_region_align = __icecap_runtime_tls_region_align_of(&config->tls_image);
        icecap_runtime_tls_region_size = __icecap_runtime_tls_region_size_of(&config->tls_image);
        icecap_runtime_image_path = config->image_path_offset == 0 ? 0 : (const char *)config + config->image_path_offset;
        icecap_runtime_print_lock = config->print_lock;
        icecap_runtime_idle_notification = config->idle_notification;
        __icecap_runtime_tls_image = config->tls_image;
        icecap_main((void *)((char *)config + config->arg.offset), config->arg.size);
        icecap_runtime_stop_component();
    } else {
        seL4_Recv(config->threads[thread_index].endpoint, 0);
        seL4_Word entry_vaddr = seL4_GetMR(0);
        seL4_Word entry_arg0 = seL4_GetMR(1);
        seL4_Word entry_arg1 = seL4_GetMR(2);
        ((icecap_runtime_secondary_thread_entry_fn)entry_vaddr)(entry_arg0, entry_arg1);
        icecap_runtime_stop_thread();
    }
}

seL4_Word icecap_runtime_tls_region_init(void *region)
{
    return __icecap_runtime_tls_region_init_of(&__icecap_runtime_tls_image, region);
}

void icecap_runtime_tls_region_insert(
    void *dst_tls_region,
    void *local_ptr,
    void *src,
    seL4_Word n
    )
{
    seL4_Word offset_into_region = (seL4_Word)local_ptr - __icecap_runtime_get_tpidr();
    seL4_Uint8 *dst = (seL4_Uint8 *)dst_tls_region + offset_into_region;
    for (int i = 0; i < n; i++) {
        dst[i] = ((seL4_Uint8 *)src)[i];
    }
}

void icecap_runtime_tls_region_insert_ipc_buffer(void *dst_tls_region, void *ipc_buffer)
{
    icecap_runtime_tls_region_insert(
        dst_tls_region,
        (void *)&__sel4_ipc_buffer,
        (void *)&ipc_buffer,
        sizeof(&ipc_buffer)
    );
}

void icecap_runtime_tls_region_insert_tcb(void *dst_tls_region, seL4_CPtr tcb)
{
    icecap_runtime_tls_region_insert(
        dst_tls_region,
        (void *)&icecap_runtime_tcb,
        (void *)&tcb,
        sizeof(&tcb)
    );
}

static void debug_print(const char *s); // HACK

void ICECAP_NORETURN icecap_runtime_stop_thread(void)
{
    if (icecap_runtime_tcb) {
        seL4_TCB_Suspend(icecap_runtime_tcb);
    }
    seL4_Wait(icecap_runtime_idle_notification, seL4_Null);
    ICECAP_UNREACHABLE();
}

void ICECAP_NORETURN icecap_runtime_stop_component(void)
{
    seL4_CPtr tcb;

    debug_print("icecap_runtime_stop_component()\n"); // HACK

    for (int i = 0; i < __icecap_runtime_config->num_threads; i++) {
        tcb = __icecap_runtime_config->threads[i].tcb;
        if (tcb && tcb != icecap_runtime_tcb) {
            seL4_TCB_Suspend(tcb);
        }
    }

    icecap_runtime_stop_thread();
}

#ifdef ICECAP_RUNTIME_ROOT

extern seL4_Word __icecap_runtime_root_tdata_start[];
extern seL4_Word __icecap_runtime_root_tdata_end[];
extern seL4_Word __icecap_runtime_root_tbss_end[];

static seL4_Uint8 __attribute__((aligned(4096))) __icecap_runtime_root_heap[ICECAP_RUNTIME_ROOT_HEAP_SIZE];

// NOTE
// This must be static both because of flexible array member ('threads'), and to allow access at runtime.
static struct icecap_runtime_config root_config = {
    .heap_info = {
        .start = (seL4_Word)&__icecap_runtime_root_heap[0],
        .end = (seL4_Word)&__icecap_runtime_root_heap[ICECAP_RUNTIME_ROOT_HEAP_SIZE],
        .lock = 0,
    },
    .image_path_offset = 0,
    .num_threads = 1,
    .threads = {
        {},
    },
};

void ICECAP_NORETURN __icecap_runtime_root_start(seL4_BootInfo *bootinfo)
{
    root_config.arg.offset = (seL4_Word)bootinfo - (seL4_Word)&root_config;
    root_config.arg.size = 0; // TODO
    root_config.threads[0].ipc_buffer = bootinfo->ipcBuffer;
    root_config.threads[0].tcb = seL4_CapInitThreadTCB;
    root_config.tls_image.vaddr = (seL4_Word)&__icecap_runtime_root_tdata_start[0];
    root_config.tls_image.filesz = (seL4_Word)&__icecap_runtime_root_tdata_end[0] - (seL4_Word)&__icecap_runtime_root_tdata_start[0];
    root_config.tls_image.memsz = (seL4_Word)&__icecap_runtime_root_tbss_end[0] - (seL4_Word)&__icecap_runtime_root_tdata_start[0];
    root_config.tls_image.align = sizeof(seL4_Word);

    __icecap_runtime_start(&root_config, 0);
}

#endif

// libsel4 depends on strcpy and __assert_fail

char __attribute__((weak)) *strcpy(char *dst, const char *src)
{
    while ((*(dst++) = *(src++)));
    return dst;
}

static void debug_print(const char *s)
{
    while (*s) {
        seL4_DebugPutChar(*s++);
    }
}

#define MAX_DIGITS 20 // 19 < log_10(2^64) <= 20

static void debug_print_decimal(int d)
{
    static const char *digits = "0123456789";
    char buf[MAX_DIGITS] = {0};
    char *cur = &buf[MAX_DIGITS] - 1;
    while (d) {
        *--cur = digits[d % 10];
        d /= 10;
    }
    debug_print(cur);
}

void __attribute__((weak)) ICECAP_NORETURN __assert_fail(const char *expr, const char *file, int line, const char *func)
{
    debug_print("__assert_fail(\"");
    debug_print(expr);
    debug_print("\", ");
    debug_print(file);
    debug_print(", ");
    debug_print_decimal(line);
    debug_print(", ");
    debug_print(func);
    debug_print(")\n");

    icecap_runtime_stop_component();
}
