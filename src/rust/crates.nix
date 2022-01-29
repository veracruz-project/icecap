{
  # framework

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
  icecap-core = ./crates/framework/base/icecap-core;
  icecap-std = ./crates/framework/base/icecap-std;

  icecap-unwind = ./crates/framework/base/icecap-unwind;
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

  absurdity = ./crates/framework/helpers/absurdity;
  biterate = ./crates/framework/helpers/biterate;
  finite-set = ./crates/framework/helpers/finite-set;
  finite-set-derive = ./crates/framework/helpers/finite-set/derive;
  generated-module-hack = ./crates/framework/helpers/generated-module-hack;
  numeric-literal-env-hack = ./crates/framework/helpers/numeric-literal-env-hack;

  icecap-std-external = ./crates/framework/std-support/icecap-std-external;
  icecap-std-impl = ./crates/framework/std-support/icecap-std-impl;

  dyndl-realize = ./crates/framework/dyndl/realize;
  dyndl-realize-simple = ./crates/framework/dyndl/realize/simple;
  dyndl-realize-simple-config = ./crates/framework/dyndl/realize/simple/config;
  dyndl-types = ./crates/framework/dyndl/types;
  dyndl-types-derive = ./crates/framework/dyndl/types/derive;
  dyndl-serialize-spec = ./crates/framework/dyndl/cli/dyndl-serialize-spec;

  icecap-vmm-gic = ./crates/framework/vmm/gic;
  icecap-vmm-psci = ./crates/framework/vmm/psci;

  icecap-mirage-core = ./crates/framework/mirage/core;

  icecap-linux-syscall-types = ./crates/framework/linux-syscall/types;
  icecap-linux-syscall-musl = ./crates/framework/linux-syscall/musl;

  icecap-serialize-generic-component-config = ./crates/framework/generic-components/icecap-serialize-generic-component-config;

  icecap-generic-timer-server = ./crates/framework/generic-components/timer-server;
  icecap-generic-timer-server-types = ./crates/framework/generic-components/timer-server/types;
  icecap-generic-timer-server-client = ./crates/framework/generic-components/timer-server/client;
  icecap-generic-timer-server-config = ./crates/framework/generic-components/timer-server/config;
  icecap-generic-serial-server-core = ./crates/framework/generic-components/serial-server/core;

  crosvm-9p = ./crates/framework/9p/crosvm-9p;
  crosvm-9p-wire-format-derive = ./crates/framework/9p/crosvm-9p/wire-format-derive;
  crosvm-9p-server = ./crates/framework/9p/crosvm-9p-server;
  crosvm-9p-server-cli = ./crates/framework/9p/crosvm-9p-server/cli;

  # hypervisor

  hypervisor-vmm-core = ./crates/hypervisor/vmm/core;
  hypervisor-fdt-append-devices = ./crates/hypervisor/build-tools/hypervisor-fdt-append-devices;
  hypervisor-serialize-component-config = ./crates/hypervisor/build-tools/hypervisor-serialize-component-config;

  icecap-host = ./crates/hypervisor/host-tools/icecap-host;
  icecap-host-core = ./crates/hypervisor/host-tools/icecap-host/core;

  hypervisor-host-vmm = ./crates/hypervisor/vmm/host;
  hypervisor-host-vmm-types = ./crates/hypervisor/vmm/host/types;
  hypervisor-host-vmm-config = ./crates/hypervisor/vmm/host/config;

  hypervisor-realm-vmm = ./crates/hypervisor/vmm/realm;
  hypervisor-realm-vmm-config = ./crates/hypervisor/vmm/realm/config;

  hypervisor-resource-server = ./crates/hypervisor/resource-server;
  hypervisor-resource-server-types = ./crates/hypervisor/resource-server/types;
  hypervisor-resource-server-core = ./crates/hypervisor/resource-server/core;
  hypervisor-resource-server-config = ./crates/hypervisor/resource-server/config;

  hypervisor-idle = ./crates/hypervisor/idle;

  hypervisor-fault-handler = ./crates/hypervisor/fault-handler;
  hypervisor-fault-handler-config = ./crates/hypervisor/fault-handler/config;

  hypervisor-event-server = ./crates/hypervisor/event-server;
  hypervisor-event-server-types = ./crates/hypervisor/event-server/types;
  hypervisor-event-server-config = ./crates/hypervisor/event-server/config;
  hypervisor-serialize-event-server-out-index = ./crates/hypervisor/build-tools/hypervisor-serialize-event-server-out-index;

  hypervisor-serial-server = ./crates/hypervisor/serial-server;
  hypervisor-serial-server-config = ./crates/hypervisor/serial-server/config;

  hypervisor-benchmark-server = ./crates/hypervisor/benchmark-server;
  hypervisor-benchmark-server-types = ./crates/hypervisor/benchmark-server/types;
  hypervisor-benchmark-server-config = ./crates/hypervisor/benchmark-server/config;

  hypervisor-mirage = ./crates/hypervisor/mirage;
  hypervisor-mirage-config = ./crates/hypervisor/mirage/config;

}
