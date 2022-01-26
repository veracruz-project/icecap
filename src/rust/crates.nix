{

  icecap-sel4 = ./crates/base/icecap-sel4;
  icecap-sel4-sys = ./crates/base/icecap-sel4/sys;
  icecap-sel4-derive = ./crates/base/icecap-sel4/derive;
  icecap-runtime = ./crates/base/icecap-runtime;
  icecap-sync = ./crates/base/icecap-sync;
  icecap-rpc = ./crates/base/icecap-rpc;
  icecap-rpc-sel4 = ./crates/base/icecap-rpc/sel4;
  icecap-ring-buffer = ./crates/base/icecap-ring-buffer;
  icecap-failure = ./crates/base/icecap-failure;
  icecap-failure-derive = ./crates/base/icecap-failure/derive;
  icecap-logger = ./crates/base/icecap-logger;
  icecap-start = ./crates/base/icecap-start;
  icecap-start-generic = ./crates/base/icecap-start/generic;
  icecap-core = ./crates/base/icecap-core;
  icecap-std = ./crates/base/icecap-std;

  icecap-unwind = ./crates/base/icecap-unwind;
  icecap-backtrace = ./crates/base/icecap-backtrace;
  icecap-backtrace-types = ./crates/base/icecap-backtrace/types;
  icecap-backtrace-collect = ./crates/base/icecap-backtrace/collect;
  icecap-show-backtrace = ./crates/base/icecap-backtrace/cli/icecap-show-backtrace;

  icecap-config = ./crates/base/icecap-config;
  icecap-config-sys = ./crates/base/icecap-config/sys;
  icecap-config-cli-core = ./crates/base/icecap-config/cli/core;

  icecap-runtime-config = ./crates/base/icecap-runtime/config;
  icecap-serialize-runtime-config = ./crates/base/icecap-runtime/config/cli/icecap-serialize-runtime-config;

  icecap-fdt = ./crates/base/icecap-fdt;

  icecap-plat = ./crates/base/icecap-plat;

  icecap-driver-interfaces = ./crates/drivers/icecap-driver-interfaces;
  icecap-bcm-system-timer-driver = ./crates/drivers/devices/bcm-system-timer;
  icecap-bcm2835-aux-uart-driver = ./crates/drivers/devices/bcm2835-aux-uart;
  icecap-pl011-driver = ./crates/drivers/devices/pl011;
  icecap-virt-timer-driver = ./crates/drivers/devices/virt-timer;

  absurdity = ./crates/helpers/absurdity;
  biterate = ./crates/helpers/biterate;
  finite-set = ./crates/helpers/finite-set;
  finite-set-derive = ./crates/helpers/finite-set/derive;
  generated-module-hack = ./crates/helpers/generated-module-hack;
  numeric-literal-env-hack = ./crates/helpers/numeric-literal-env-hack;


  icecap-std-external = ./crates/std-support/icecap-std-external;
  icecap-std-impl = ./crates/std-support/icecap-std-impl;


  dyndl-realize = ./crates/dyndl/realize;
  dyndl-realize-simple = ./crates/dyndl/realize/simple;
  dyndl-realize-simple-config = ./crates/dyndl/realize/simple/config;
  dyndl-types = ./crates/dyndl/types;
  dyndl-types-derive = ./crates/dyndl/types/derive;
  dyndl-serialize-spec = ./crates/dyndl/cli/dyndl-serialize-spec;


  icecap-vmm = ./crates/hypervisor/icecap-vmm;
  icecap-vmm-gic = ./crates/hypervisor/icecap-vmm/gic;
  icecap-fdt-bindings = ./crates/hypervisor/icecap-fdt-bindings;
  icecap-append-devices = ./crates/hypervisor/icecap-fdt-bindings/cli/icecap-append-devices;
  icecap-serialize-builtin-config = ./crates/hypervisor/icecap-serialize-builtin-config;

  icecap-host = ./crates/hypervisor/components/host/user/cli;
  icecap-host-user = ./crates/hypervisor/components/host/user;

  host-vmm = ./crates/hypervisor/components/host/vmm;
  icecap-host-vmm-types = ./crates/hypervisor/components/host/vmm/types;
  icecap-host-vmm-config = ./crates/hypervisor/components/host/vmm/config;

  realm-vmm = ./crates/hypervisor/components/realm/vmm;
  icecap-realm-vmm-config = ./crates/hypervisor/components/realm/vmm/config;

  resource-server = ./crates/hypervisor/components/resource-server;
  icecap-resource-server-types = ./crates/hypervisor/components/resource-server/types;
  icecap-resource-server-core = ./crates/hypervisor/components/resource-server/core;
  icecap-resource-server-config = ./crates/hypervisor/components/resource-server/config;

  idle = ./crates/hypervisor/components/idle;

  fault-handler = ./crates/hypervisor/components/fault-handler;
  icecap-fault-handler-config = ./crates/hypervisor/components/fault-handler/config;

  timer-server = ./crates/hypervisor/components/timer-server;
  icecap-timer-server-types = ./crates/hypervisor/components/timer-server/types;
  icecap-timer-server-config = ./crates/hypervisor/components/timer-server/config;
  icecap-timer-server-client = ./crates/hypervisor/components/timer-server/client;

  event-server = ./crates/hypervisor/components/event-server;
  icecap-event-server-types = ./crates/hypervisor/components/event-server/types;
  icecap-event-server-config = ./crates/hypervisor/components/event-server/config;
  icecap-serialize-event-server-out-index = ./crates/hypervisor/components/event-server/types/cli/icecap-serialize-event-server-out-index;

  serial-server = ./crates/hypervisor/components/serial-server;
  icecap-serial-server-config = ./crates/hypervisor/components/serial-server/config;

  benchmark-server = ./crates/hypervisor/components/benchmark-server;
  icecap-benchmark-server-types = ./crates/hypervisor/components/benchmark-server/types;
  icecap-benchmark-server-config = ./crates/hypervisor/components/benchmark-server/config;

  mirage = ./crates/hypervisor/components/mirage;
  icecap-mirage-config = ./crates/hypervisor/components/mirage/config;
  icecap-linux-syscall = ./crates/hypervisor/components/mirage/icecap-linux-syscall;


  crosvm-9p = ./crates/9p/crosvm-9p;
  crosvm-9p-wire-format-derive = ./crates/9p/crosvm-9p/wire-format-derive;
  crosvm-9p-server = ./crates/9p/crosvm-9p-server;
  crosvm-9p-server-cli = ./crates/9p/crosvm-9p-server/cli;

}
