#pragma once

#include <stdlib.h>

typedef size_t value_handle;
typedef size_t net_iface_id;

// exports to rust

int costub_run_mirage(void);
void costub_alloc(size_t size, value_handle *handle, char **buf);

// imports from rust

void impl_wfe(void);

uint64_t impl_get_time_ns(void);
void impl_set_timeout_ns(uint64_t ns);

size_t impl_num_net_ifaces(void);
int impl_net_iface_poll(net_iface_id id);
void impl_net_iface_tx(net_iface_id id, char *buf, size_t n);
value_handle impl_net_iface_rx(net_iface_id id);
