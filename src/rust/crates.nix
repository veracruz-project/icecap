{

  icecap-sel4 = ./crates/framework/icecap-sel4;
  icecap-sel4-sys = ./crates/framework/icecap-sel4/sys;
  icecap-sel4-derive = ./crates/framework/icecap-sel4/derive;
  icecap-runtime = ./crates/framework/icecap-runtime;
  icecap-sync = ./crates/framework/icecap-sync;
  icecap-rpc = ./crates/framework/icecap-rpc;
  icecap-rpc-sel4 = ./crates/framework/icecap-rpc/sel4;
  icecap-ring-buffer = ./crates/framework/icecap-ring-buffer;
  icecap-failure = ./crates/framework/icecap-failure;
  icecap-failure-derive = ./crates/framework/icecap-failure/derive;
  icecap-logger = ./crates/framework/icecap-logger;
  icecap-start = ./crates/framework/icecap-start;
  icecap-start-generic = ./crates/framework/icecap-start/generic;
  icecap-core = ./crates/framework/icecap-core;
  icecap-std = ./crates/framework/icecap-std;

  icecap-unwind = ./crates/framework/icecap-unwind;
  icecap-backtrace = ./crates/framework/icecap-backtrace;
  icecap-backtrace-types = ./crates/framework/icecap-backtrace/types;
  icecap-backtrace-collect = ./crates/framework/icecap-backtrace/collect;
  icecap-show-backtrace = ./crates/framework/icecap-backtrace/cli/icecap-show-backtrace;

  icecap-config = ./crates/framework/icecap-config;
  icecap-config-sys = ./crates/framework/icecap-config/sys;
  icecap-config-cli-core = ./crates/framework/icecap-config/cli/core;

  icecap-runtime-config = ./crates/framework/icecap-runtime/config;
  icecap-serialize-runtime-config = ./crates/framework/icecap-runtime/config/cli/icecap-serialize-runtime-config;

  icecap-fdt = ./crates/framework/icecap-fdt;

  icecap-plat = ./crates/framework/icecap-plat;

  icecap-drivers = ./crates/drivers/icecap-drivers-lame;


  absurdity = ./crates/helpers/absurdity;
  biterate = ./crates/helpers/biterate;
  finite-set = ./crates/helpers/finite-set;
  finite-set-derive = ./crates/helpers/finite-set/derive;
  generated-module-hack = ./crates/helpers/generated-module-hack;
  numeric-literal-env-hack = ./crates/helpers/numeric-literal-env-hack;


  icecap-std-external = ./crates/std-support/icecap-std-external;
  icecap-std-impl = ./crates/std-support/icecap-std-impl;


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
  icecap-linux-syscall = ./crates/hypervisor/components/mirage/icecap-linux-syscall;


  crosvm-9p = ./crates/9p/crosvm-9p;
  crosvm-9p-wire-format-derive = ./crates/9p/crosvm-9p/wire-format-derive;
  crosvm-9p-server = ./crates/9p/crosvm-9p-server;
  crosvm-9p-server-cli = ./crates/9p/crosvm-9p-server/cli;

}
