{ lib, seL4, debug }:

with lib;

let
  seL4Only = if seL4 then id else const null;
in

filterAttrs (_: v: v != null) {

  dyndl-types = ./dyndl/types;
  dyndl-types-derive = ./dyndl/types/derive;
  dyndl-serialize-spec = ./dyndl/cli/dyndl-serialize-spec;

  icecap-host = ./components/host;
  icecap-host-core = ./components/host/core;

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

  icecap-rpc = ./icecap/icecap-rpc;
  icecap-rpc-sel4 = seL4Only ./icecap/icecap-rpc/sel4;
  icecap-config = ./icecap/icecap-config;
  icecap-config-sys = ./icecap/icecap-config/sys + "/${if seL4 then "icecap" else "linux"}";
  icecap-config-cli-core = ./icecap/icecap-config/cli/core;

  icecap-p9 = ./9p/icecap-p9;
  icecap-p9-wire-format-derive = ./9p/icecap-p9/wire-format-derive;
  icecap-p9-server-linux = ./9p/icecap-p9-server-linux;
  icecap-p9-server-linux-cli = ./9p/icecap-p9-server-linux/cli;

  generated-module-hack = ./helpers/generated-module-hack;
  finite-set = ./helpers/finite-set;
  finite-set-derive = ./helpers/finite-set/derive;
  finite-set-derive-impl = ./helpers/finite-set/derive/impl;

  icecap-sel4 = seL4Only ./icecap/icecap-sel4;
  icecap-sel4-sys = seL4Only ./icecap/icecap-sel4/sys;
  icecap-sel4-derive = seL4Only ./icecap/icecap-sel4/derive;
  icecap-runtime = seL4Only ./icecap/icecap-runtime;
  icecap-sync = seL4Only ./icecap/icecap-sync;
  icecap-ring-buffer = seL4Only ./icecap/icecap-ring-buffer;
  icecap-failure = seL4Only ./icecap/icecap-failure;
  icecap-failure-derive = seL4Only ./icecap/icecap-failure/derive;
  icecap-start = seL4Only ./icecap/icecap-start;
  icecap-start-generic = seL4Only ./icecap/icecap-start/generic;
  icecap-core = seL4Only ./icecap/icecap-core;
  icecap-std = seL4Only ./icecap/icecap-std;

  icecap-std-external = seL4Only ./std-support/icecap-std-external;
  icecap-std-impl = seL4Only ./std-support/icecap-std-impl;

  vmm = seL4Only ./components/vmm;
  icecap-vmm-core = seL4Only ./components/vmm/core;
  icecap-vmm-config = ./components/vmm/config;

  resource-server = seL4Only ./components/resource-server;
  icecap-resource-server-types = ./components/resource-server/types;
  icecap-resource-server-core = seL4Only ./components/resource-server/core;
  icecap-resource-server-config = ./components/resource-server/config;

  idle = seL4Only ./components/idle;

  fault-handler = seL4Only ./components/fault-handler;
  icecap-fault-handler-config = ./components/fault-handler/config;

  timer-server = seL4Only ./components/timer-server;
  icecap-timer-server-types = seL4Only ./components/timer-server/types;
  icecap-timer-server-config = ./components/timer-server/config;
  icecap-timer-server-client = seL4Only ./components/timer-server/client;

  event-server = seL4Only ./components/event-server;
  icecap-event-server-types = seL4Only ./components/event-server/types;
  icecap-event-server-config = ./components/event-server/config;
  icecap-event-server-client = seL4Only ./components/event-server/client;

  serial-server = seL4Only ./components/serial-server;
  icecap-serial-server-config = ./components/serial-server/config;

  qemu-ring-buffer-server = seL4Only ./components/qemu-ring-buffer-server;
  icecap-qemu-ring-buffer-server-config = ./components/qemu-ring-buffer-server/config;

  mirage = seL4Only ./components/mirage;
  icecap-linux-syscall = seL4Only ./components/mirage/icecap-linux-syscall;

}
