{
  ### framework ###

  icecap-sel4 = ./crates/framework/base/icecap-sel4;
  icecap-sel4-sys = ./crates/framework/base/icecap-sel4/sys;
  icecap-sel4-derive = ./crates/framework/base/icecap-sel4/derive;
  icecap-runtime = ./crates/framework/base/icecap-runtime;
  icecap-sync = ./crates/framework/base/icecap-sync;
  icecap-rpc = ./crates/framework/base/icecap-rpc;
  icecap-rpc-types = ./crates/framework/base/icecap-rpc/types;
  icecap-ring-buffer = ./crates/framework/base/icecap-ring-buffer;
  icecap-failure = ./crates/framework/base/icecap-failure;
  icecap-failure-derive = ./crates/framework/base/icecap-failure/derive;
  icecap-logger = ./crates/framework/base/icecap-logger;
  icecap-start = ./crates/framework/base/icecap-start;
  icecap-start-generic = ./crates/framework/base/icecap-start/generic;
  icecap-dlmalloc = ./crates/framework/base/icecap-dlmalloc;
  icecap-core = ./crates/framework/base/icecap-core;
  icecap-std = ./crates/framework/base/icecap-std;

  icecap-backtrace = ./crates/framework/base/icecap-backtrace;
  icecap-backtrace-types = ./crates/framework/base/icecap-backtrace/types;
  icecap-backtrace-collect = ./crates/framework/base/icecap-backtrace/collect;
  icecap-show-backtrace = ./crates/framework/base/icecap-backtrace/cli/icecap-show-backtrace;

  icecap-config = ./crates/framework/base/icecap-config;
  icecap-config-sys = ./crates/framework/base/icecap-config/sys;
  icecap-config-cli-core = ./crates/framework/base/icecap-config/cli/core;

  icecap-runtime-config = ./crates/framework/base/icecap-runtime/config;
  icecap-serialize-runtime-config = ./crates/framework/base/icecap-runtime/config/cli/icecap-serialize-runtime-config;

  icecap-fdt = ./crates/framework/base/icecap-fdt;
  icecap-fdt-bindings = ./crates/framework/base/icecap-fdt/bindings;

  icecap-plat = ./crates/framework/base/icecap-plat;

  icecap-driver-interfaces = ./crates/framework/drivers/icecap-driver-interfaces;
  icecap-bcm-system-timer-driver = ./crates/framework/drivers/devices/bcm-system-timer;
  icecap-bcm2835-aux-uart-driver = ./crates/framework/drivers/devices/bcm2835-aux-uart;
  icecap-pl011-driver = ./crates/framework/drivers/devices/pl011;
  icecap-virt-timer-driver = ./crates/framework/drivers/devices/virt-timer;

  icecap-vmm-gic = ./crates/framework/vmm/gic;
  icecap-vmm-psci = ./crates/framework/vmm/psci;
  icecap-vmm-utils = ./crates/framework/vmm/utils;

  icecap-mirage-core = ./crates/framework/mirage/core;

  icecap-linux-syscall-types = ./crates/framework/linux-syscall/types;
  icecap-linux-syscall-musl = ./crates/framework/linux-syscall/musl;

  # helpers

  absurdity = ./crates/framework/helpers/absurdity;
  biterate = ./crates/framework/helpers/biterate;
  finite-set = ./crates/framework/helpers/finite-set;
  finite-set-derive = ./crates/framework/helpers/finite-set/derive;
  generated-module-hack = ./crates/framework/helpers/generated-module-hack;
  numeric-literal-env-hack = ./crates/framework/helpers/numeric-literal-env-hack;

  # std support

  icecap-std-external = ./crates/framework/std-support/icecap-std-external;
  icecap-std-impl = ./crates/framework/std-support/icecap-std-impl;

  # dyndl

  dyndl-realize = ./crates/framework/dyndl/realize;
  dyndl-realize-simple = ./crates/framework/dyndl/realize/simple;
  dyndl-realize-simple-config = ./crates/framework/dyndl/realize/simple/config;
  dyndl-types = ./crates/framework/dyndl/types;
  dyndl-types-derive = ./crates/framework/dyndl/types/derive;
  dyndl-serialize-spec = ./crates/framework/dyndl/cli/dyndl-serialize-spec;

  # generic components

  icecap-serialize-generic-component-config = ./crates/framework/generic-components/icecap-serialize-generic-component-config;

  icecap-generic-timer-server = ./crates/framework/generic-components/timer-server;
  icecap-generic-timer-server-types = ./crates/framework/generic-components/timer-server/types;
  icecap-generic-timer-server-client = ./crates/framework/generic-components/timer-server/client;
  icecap-generic-timer-server-config = ./crates/framework/generic-components/timer-server/config;
  icecap-generic-serial-server-core = ./crates/framework/generic-components/serial-server/core;

  # 9p

  crosvm-9p = ./crates/framework/9p/crosvm-9p;
  crosvm-9p-wire-format-derive = ./crates/framework/9p/crosvm-9p/wire-format-derive;
  crosvm-9p-server = ./crates/framework/9p/crosvm-9p-server;
  crosvm-9p-server-cli = ./crates/framework/9p/crosvm-9p-server/cli;


  ### hypervisor ###

  hypervisor-resource-server = ./crates/hypervisor/components/resource-server;
  hypervisor-resource-server-types = ./crates/hypervisor/components/resource-server/types;
  hypervisor-resource-server-core = ./crates/hypervisor/components/resource-server/core;
  hypervisor-resource-server-config = ./crates/hypervisor/components/resource-server/config;

  hypervisor-event-server = ./crates/hypervisor/components/event-server;
  hypervisor-event-server-types = ./crates/hypervisor/components/event-server/types;
  hypervisor-event-server-config = ./crates/hypervisor/components/event-server/config;

  hypervisor-serial-server = ./crates/hypervisor/components/serial-server;
  hypervisor-serial-server-config = ./crates/hypervisor/components/serial-server/config;

  hypervisor-benchmark-server = ./crates/hypervisor/components/benchmark-server;
  hypervisor-benchmark-server-types = ./crates/hypervisor/components/benchmark-server/types;
  hypervisor-benchmark-server-config = ./crates/hypervisor/components/benchmark-server/config;

  hypervisor-fault-handler = ./crates/hypervisor/components/fault-handler;
  hypervisor-fault-handler-config = ./crates/hypervisor/components/fault-handler/config;

  hypervisor-idle = ./crates/hypervisor/components/idle;

  hypervisor-vmm-core = ./crates/hypervisor/components/vmm/core;
  hypervisor-host-vmm = ./crates/hypervisor/components/vmm/host;
  hypervisor-host-vmm-types = ./crates/hypervisor/components/vmm/host/types;
  hypervisor-host-vmm-config = ./crates/hypervisor/components/vmm/host/config;
  hypervisor-realm-vmm = ./crates/hypervisor/components/vmm/realm;
  hypervisor-realm-vmm-config = ./crates/hypervisor/components/vmm/realm/config;

  hypervisor-mirage = ./crates/hypervisor/components/mirage;
  hypervisor-mirage-config = ./crates/hypervisor/components/mirage/config;

  # NOTE named with "icecap-" for aesthetics
  icecap-host = ./crates/hypervisor/host-tools/icecap-host;
  icecap-host-core = ./crates/hypervisor/host-tools/icecap-host/core;

  hypervisor-fdt-append-devices = ./crates/hypervisor/build-tools/hypervisor-fdt-append-devices;
  hypervisor-serialize-component-config = ./crates/hypervisor/build-tools/hypervisor-serialize-component-config;
  hypervisor-serialize-event-server-out-index = ./crates/hypervisor/build-tools/hypervisor-serialize-event-server-out-index;

}
