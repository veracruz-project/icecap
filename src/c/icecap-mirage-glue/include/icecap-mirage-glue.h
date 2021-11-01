#pragma once

#include <stdlib.h>

#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

typedef size_t value_handle;
typedef size_t net_iface_id;

// exports to rust

void costub_startup(void);
void costub_alloc(size_t size, value_handle *handle, char **buf);
int costub_run_main(size_t handle);

// imports from rust

void impl_wfe(void);

uint64_t impl_get_time_ns(void);
void impl_set_timeout_ns(uint64_t ns);

size_t impl_num_net_ifaces(void);
int impl_net_iface_poll(net_iface_id id);
void impl_net_iface_tx(net_iface_id id, char *buf, size_t n);
value_handle impl_net_iface_rx(net_iface_id id);

// exports to ocaml

CAMLprim value
stub_wfe(value unit);

CAMLprim value
caml_get_monotonic_time(value unit);

CAMLprim value
stub_set_timeout_ns(value v_d);

CAMLprim value
stub_num_net_ifaces(value unit);

CAMLprim value
stub_net_iface_poll(value v_net_iface_id);

CAMLprim value
stub_net_iface_rx(value v_net_driver_id);

CAMLprim value
stub_net_iface_tx(value v_net_iface_id, value v_buf);
