{ lib, seL4, debug }:

lib.fix (self: with self; {

  icecap-sel4_dummy = ./icecap/icecap-sel4/dummy;
  icecap-runtime_dummy = ./icecap/icecap-runtime/dummy;
  icecap-failure_dummy = ./icecap/icecap-failure/dummy;
  icecap-backtrace_dummy = ./icecap/icecap-backtrace/dummy;

  dyndl-types = ./components/caput/dyndl-types;
  dyndl-types-derive = ./components/caput/dyndl-types/derive;
  icecap-caput-types = ./components/caput/types;
  icecap-caput-host = ./components/caput/host;

  icecap-fdt = ./icecap/icecap-fdt;
  icecap-fdt-bindings = ./icecap/icecap-fdt/bindings;
  icecap-backtrace-types = ./icecap/icecap-backtrace/types;

  icecap-runtime-config = ./icecap/icecap-runtime/config;
  icecap-base-config = ./icecap/icecap-base-config;
  icecap-vmm-config = ./components/vmm/config;
  icecap-caput-config = ./components/caput/config;
  icecap-fault-handler-config = ./components/fault-handler/config;
  icecap-timer-server-config = ./components/timer-server/config;
  icecap-serial-server-config = ./components/serial-server/config;
  icecap-qemu-ring-buffer-server-config = ./components/qemu-ring-buffer-server/config;

  icecap-p9 = ./9p/icecap-p9;
  icecap-p9-wire-format-derive = ./9p/icecap-p9/wire-format-derive;
  icecap-p9-server-linux = ./9p/icecap-p9-server-linux;
  icecap-p9-server-linux-cli = ./9p/icecap-p9-server-linux/cli;

  create-realm = ./helpers/create-realm;
  append-icecap-devices = ./helpers/append-icecap-devices;
  icecap-serialize-config = ./helpers/icecap-serialize-config;
  serialize-dyndl-spec = ./helpers/serialize-dyndl-spec;
  serialize-runtime-config = ./helpers/serialize-runtime-config;
  show-backtrace = ./helpers/show-backtrace;
  generated-module-hack = ./helpers/generated-module-hack;

} // (if seL4 then {

  icecap-std = ./icecap/icecap-std;
  icecap-core = ./icecap/icecap-core;
  icecap-sel4 = ./icecap/icecap-sel4;
  icecap-sel4-sys = ./icecap/icecap-sel4/sys;
  icecap-sel4-derive = ./icecap/icecap-sel4/derive;
  icecap-failure = ./icecap/icecap-failure;
  icecap-failure-derive = ./icecap/icecap-failure/derive;
  icecap-sync = ./icecap/icecap-sync;
  icecap-interfaces = ./icecap/icecap-interfaces;
  icecap-base-config-realize = ./icecap/icecap-base-config/realize;
  icecap-net = ./icecap/icecap-net;
  icecap-runtime = ./icecap/icecap-runtime;
  icecap-start = ./icecap/icecap-start;
  icecap-start-generic = ./icecap/icecap-start/generic;

  icecap-std-external = ./std-support/icecap-std-external;
  icecap-std-impl = ./std-support/icecap-std-impl;

  vmm = ./components/vmm;
  icecap-vmm-core = ./components/vmm/core;

  caput = ./components/caput;
  dyndl-realize = ./components/caput/dyndl-realize;

  fault-handler = ./components/fault-handler;

  timer-server = ./components/timer-server;
  serial-server = ./components/serial-server;
  qemu-ring-buffer-server = ./components/qemu-ring-buffer-server;

  mirage = ./components/mirage;
  icecap-linux-syscall = ./components/mirage/icecap-linux-syscall;

} else { # !seL4

  icecap-sel4 = icecap-sel4_dummy;
  icecap-runtime = icecap-runtime_dummy;
  icecap-failure = icecap-failure_dummy;
  icecap-backtrace = icecap-backtrace_dummy;

}) // (if debug then {

  icecap-backtrace = ./icecap/icecap-backtrace;

} else { # !debug

  icecap-backtrace = icecap-backtrace_dummy;

}))
