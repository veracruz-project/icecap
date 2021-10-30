{

  dyndl-types = ./dyndl/types;
  dyndl-types-derive = ./dyndl/types/derive;
  dyndl-serialize-spec = ./dyndl/cli/dyndl-serialize-spec;

  icecap-host = ./components/host/user/cli;
  icecap-host-user = ./components/host/user;

  icecap-fdt = ./icecap/icecap-fdt;
  icecap-fdt-bindings = ./icecap/icecap-fdt/bindings;
  icecap-append-devices = ./icecap/icecap-fdt/bindings/cli/icecap-append-devices;

  icecap-unwind = ./icecap/icecap-unwind;
  icecap-backtrace = ./icecap/icecap-backtrace;
  icecap-backtrace-types = ./icecap/icecap-backtrace/types;
  icecap-backtrace-collect = ./icecap/icecap-backtrace/collect;
  icecap-show-backtrace = ./icecap/icecap-backtrace/cli/icecap-show-backtrace;

  icecap-runtime-config = ./icecap/icecap-runtime/config;
  icecap-serialize-runtime-config = ./icecap/icecap-runtime/config/cli/icecap-serialize-runtime-config;

  icecap-rpc = ./icecap/icecap-rpc;
  icecap-rpc-sel4 = ./icecap/icecap-rpc/sel4;
  icecap-config = ./icecap/icecap-config;
  icecap-config-sys = ./icecap/icecap-config/sys;
  icecap-config-cli-core = ./icecap/icecap-config/cli/core;
  icecap-serialize-builtin-config = ./icecap/icecap-config/cli/builtins;

  crosvm-9p = ./9p/crosvm-9p;
  crosvm-9p-wire-format-derive = ./9p/crosvm-9p/wire-format-derive;
  crosvm-9p-server = ./9p/crosvm-9p-server;
  crosvm-9p-server-cli = ./9p/crosvm-9p-server/cli;

  absurdity = ./helpers/absurdity;
  biterate = ./helpers/biterate;
  finite-set = ./helpers/finite-set;
  finite-set-derive = ./helpers/finite-set/derive;
  generated-module-hack = ./helpers/generated-module-hack;
  numeric-literal-env-hack = ./helpers/numeric-literal-env-hack;

  icecap-sel4 = ./icecap/icecap-sel4;
  icecap-sel4-sys = ./icecap/icecap-sel4/sys;
  icecap-sel4-derive = ./icecap/icecap-sel4/derive;
  icecap-runtime = ./icecap/icecap-runtime;
  icecap-sync = ./icecap/icecap-sync;
  icecap-ring-buffer = ./icecap/icecap-ring-buffer;
  icecap-failure = ./icecap/icecap-failure;
  icecap-failure-derive = ./icecap/icecap-failure/derive;
  icecap-logger = ./icecap/icecap-logger;
  icecap-start = ./icecap/icecap-start;
  icecap-start-generic = ./icecap/icecap-start/generic;
  icecap-core = ./icecap/icecap-core;
  icecap-std = ./icecap/icecap-std;

  icecap-plat = ./icecap/icecap-plat;

  icecap-vmm = ./icecap/icecap-vmm;
  icecap-vmm-gic = ./icecap/icecap-vmm/gic;

  icecap-std-external = ./std-support/icecap-std-external;
  icecap-std-impl = ./std-support/icecap-std-impl;

  host-vmm = ./components/host/vmm;
  icecap-host-vmm-types = ./components/host/vmm/types;
  icecap-host-vmm-config = ./components/host/vmm/config;

  realm-vmm = ./components/realm/vmm;
  icecap-realm-vmm-config = ./components/realm/vmm/config;

  resource-server = ./components/resource-server;
  icecap-resource-server-types = ./components/resource-server/types;
  icecap-resource-server-core = ./components/resource-server/core;
  icecap-resource-server-config = ./components/resource-server/config;

  idle = ./components/idle;

  fault-handler = ./components/fault-handler;
  icecap-fault-handler-config = ./components/fault-handler/config;

  timer-server = ./components/timer-server;
  icecap-timer-server-types = ./components/timer-server/types;
  icecap-timer-server-config = ./components/timer-server/config;
  icecap-timer-server-client = ./components/timer-server/client;

  event-server = ./components/event-server;
  icecap-event-server-types = ./components/event-server/types;
  icecap-event-server-config = ./components/event-server/config;
  icecap-serialize-event-server-out-index = ./components/event-server/types/cli/icecap-serialize-event-server-out-index;

  serial-server = ./components/serial-server;
  icecap-serial-server-config = ./components/serial-server/config;

  mirage = ./components/mirage;
  icecap-linux-syscall = ./components/mirage/icecap-linux-syscall;

  benchmark-server = ./components/benchmark-server;
  icecap-benchmark-server-types = ./components/benchmark-server/types;
  icecap-benchmark-server-config = ./components/benchmark-server/config;

}
