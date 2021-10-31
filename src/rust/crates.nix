{

  dyndl-types = ./crates/dyndl/types;
  dyndl-types-derive = ./crates/dyndl/types/derive;
  dyndl-serialize-spec = ./crates/dyndl/cli/dyndl-serialize-spec;

  icecap-host = ./crates/components/host/user/cli;
  icecap-host-user = ./crates/components/host/user;

  icecap-fdt = ./crates/icecap/icecap-fdt;
  icecap-fdt-bindings = ./crates/icecap/icecap-fdt/bindings;
  icecap-append-devices = ./crates/icecap/icecap-fdt/bindings/cli/icecap-append-devices;

  icecap-unwind = ./crates/icecap/icecap-unwind;
  icecap-backtrace = ./crates/icecap/icecap-backtrace;
  icecap-backtrace-types = ./crates/icecap/icecap-backtrace/types;
  icecap-backtrace-collect = ./crates/icecap/icecap-backtrace/collect;
  icecap-show-backtrace = ./crates/icecap/icecap-backtrace/cli/icecap-show-backtrace;

  icecap-runtime-config = ./crates/icecap/icecap-runtime/config;
  icecap-serialize-runtime-config = ./crates/icecap/icecap-runtime/config/cli/icecap-serialize-runtime-config;

  icecap-rpc = ./crates/icecap/icecap-rpc;
  icecap-rpc-sel4 = ./crates/icecap/icecap-rpc/sel4;
  icecap-config = ./crates/icecap/icecap-config;
  icecap-config-sys = ./crates/icecap/icecap-config/sys;
  icecap-config-cli-core = ./crates/icecap/icecap-config/cli/core;
  icecap-serialize-builtin-config = ./crates/icecap/icecap-config/cli/builtins;

  crosvm-9p = ./crates/9p/crosvm-9p;
  crosvm-9p-wire-format-derive = ./crates/9p/crosvm-9p/wire-format-derive;
  crosvm-9p-server = ./crates/9p/crosvm-9p-server;
  crosvm-9p-server-cli = ./crates/9p/crosvm-9p-server/cli;

  absurdity = ./crates/helpers/absurdity;
  biterate = ./crates/helpers/biterate;
  finite-set = ./crates/helpers/finite-set;
  finite-set-derive = ./crates/helpers/finite-set/derive;
  generated-module-hack = ./crates/helpers/generated-module-hack;
  numeric-literal-env-hack = ./crates/helpers/numeric-literal-env-hack;

  icecap-sel4 = ./crates/icecap/icecap-sel4;
  icecap-sel4-sys = ./crates/icecap/icecap-sel4/sys;
  icecap-sel4-derive = ./crates/icecap/icecap-sel4/derive;
  icecap-runtime = ./crates/icecap/icecap-runtime;
  icecap-sync = ./crates/icecap/icecap-sync;
  icecap-ring-buffer = ./crates/icecap/icecap-ring-buffer;
  icecap-failure = ./crates/icecap/icecap-failure;
  icecap-failure-derive = ./crates/icecap/icecap-failure/derive;
  icecap-logger = ./crates/icecap/icecap-logger;
  icecap-start = ./crates/icecap/icecap-start;
  icecap-start-generic = ./crates/icecap/icecap-start/generic;
  icecap-core = ./crates/icecap/icecap-core;
  icecap-std = ./crates/icecap/icecap-std;

  icecap-plat = ./crates/icecap/icecap-plat;

  icecap-vmm = ./crates/icecap/icecap-vmm;
  icecap-vmm-gic = ./crates/icecap/icecap-vmm/gic;

  icecap-std-external = ./crates/std-support/icecap-std-external;
  icecap-std-impl = ./crates/std-support/icecap-std-impl;

  host-vmm = ./crates/components/host/vmm;
  icecap-host-vmm-types = ./crates/components/host/vmm/types;
  icecap-host-vmm-config = ./crates/components/host/vmm/config;

  realm-vmm = ./crates/components/realm/vmm;
  icecap-realm-vmm-config = ./crates/components/realm/vmm/config;

  resource-server = ./crates/components/resource-server;
  icecap-resource-server-types = ./crates/components/resource-server/types;
  icecap-resource-server-core = ./crates/components/resource-server/core;
  icecap-resource-server-config = ./crates/components/resource-server/config;

  idle = ./crates/components/idle;

  fault-handler = ./crates/components/fault-handler;
  icecap-fault-handler-config = ./crates/components/fault-handler/config;

  timer-server = ./crates/components/timer-server;
  icecap-timer-server-types = ./crates/components/timer-server/types;
  icecap-timer-server-config = ./crates/components/timer-server/config;
  icecap-timer-server-client = ./crates/components/timer-server/client;

  event-server = ./crates/components/event-server;
  icecap-event-server-types = ./crates/components/event-server/types;
  icecap-event-server-config = ./crates/components/event-server/config;
  icecap-serialize-event-server-out-index = ./crates/components/event-server/types/cli/icecap-serialize-event-server-out-index;

  serial-server = ./crates/components/serial-server;
  icecap-serial-server-config = ./crates/components/serial-server/config;

  mirage = ./crates/components/mirage;
  icecap-linux-syscall = ./crates/components/mirage/icecap-linux-syscall;

  benchmark-server = ./crates/components/benchmark-server;
  icecap-benchmark-server-types = ./crates/components/benchmark-server/types;
  icecap-benchmark-server-config = ./crates/components/benchmark-server/config;

}
