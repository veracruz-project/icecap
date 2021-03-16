{ lib, seL4, debug }:

{

  dyndl-types = ./dyndl/types;
  dyndl-types-derive = ./dyndl/types/derive;
  dyndl-serialize-spec = ./dyndl/cli/dyndl-serialize-spec;

  icecap-host = ./components/host;
  icecap-host-core = ./components/host/core;
  icecap-caput-types = ./components/caput/types;

  icecap-fdt = ./icecap/icecap-fdt;
  icecap-fdt-bindings = ./icecap/icecap-fdt/bindings;
  icecap-append-devices = ./icecap/icecap-fdt/bindings/cli/icecap-append-devices;

  icecap-unwind = ./icecap/icecap-unwind;
  icecap-backtrace = ./icecap/icecap-backtrace;
  icecap-backtrace-types = ./icecap/icecap-backtrace/types;
  icecap-backtrace-collect = ./icecap/icecap-backtrace/collect + lib.optionalString (!debug || !seL4) "/dummy";
  icecap-show-backtrace = ./icecap/icecap-backtrace/cli/icecap-show-backtrace;

  icecap-runtime-config = ./icecap/icecap-runtime/config;
  icecap-serialize-runtime-config = ./icecap/icecap-runtime/config/cli/icecap-serialize-runtime-config;

  icecap-config = ./icecap/icecap-config;
  icecap-config-sys = ./icecap/icecap-config/sys + "/${if seL4 then "icecap" else "linux"}";
  icecap-config-cli-core = ./icecap/icecap-config/cli/core;

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

  generated-module-hack = ./helpers/generated-module-hack;

} // lib.optionalAttrs seL4 {

  icecap-sel4 = ./icecap/icecap-sel4;
  icecap-sel4-sys = ./icecap/icecap-sel4/sys;
  icecap-sel4-derive = ./icecap/icecap-sel4/derive;
  icecap-runtime = ./icecap/icecap-runtime;
  icecap-sync = ./icecap/icecap-sync;
  icecap-interfaces = ./icecap/icecap-interfaces;
  icecap-net = ./icecap/icecap-net;
  icecap-config-realize = ./icecap/icecap-config/realize;
  icecap-failure = ./icecap/icecap-failure;
  icecap-failure-derive = ./icecap/icecap-failure/derive;
  icecap-start = ./icecap/icecap-start;
  icecap-start-generic = ./icecap/icecap-start/generic;
  icecap-core = ./icecap/icecap-core;
  icecap-std = ./icecap/icecap-std;

  icecap-std-external = ./std-support/icecap-std-external;
  icecap-std-impl = ./std-support/icecap-std-impl;

  vmm = ./components/vmm;
  icecap-vmm-core = ./components/vmm/core;

  caput = ./components/caput;
  icecap-caput-core = ./components/caput/core;

  fault-handler = ./components/fault-handler;

  timer-server = ./components/timer-server;
  serial-server = ./components/serial-server;
  qemu-ring-buffer-server = ./components/qemu-ring-buffer-server;

  mirage = ./components/mirage;
  icecap-linux-syscall = ./components/mirage/icecap-linux-syscall;

}
