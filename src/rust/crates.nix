{
  icecap-std = ./icecap/icecap-std;
  icecap-core = ./icecap/icecap-core;
  icecap-sel4 = ./icecap/icecap-sel4;
  icecap-sel4-sys = ./icecap/icecap-sel4/sys;
  icecap-sel4-derive = ./icecap/icecap-sel4/derive;
  icecap-failure = ./icecap/icecap-failure;
  icecap-failure-derive = ./icecap/icecap-failure/derive;
  icecap-backtrace = ./icecap/icecap-backtrace;
  icecap-backtrace-types = ./icecap/icecap-backtrace/types;
  icecap-fdt = ./icecap/icecap-fdt;
  icecap-fdt-bindings = ./icecap/icecap-fdt/bindings;
  icecap-interfaces = ./icecap/icecap-interfaces;
  icecap-net = ./icecap/icecap-net;
  icecap-runtime = ./icecap/icecap-runtime;
  icecap-runtime-config = ./icecap/icecap-runtime/config;
  icecap-start = ./icecap/icecap-start;

  icecap-config-common = ./icecap/icecap-config-common;
  icecap-realize-config = ./icecap/icecap-realize-config;
  icecap-sel4-hack = ./icecap/icecap-config-common/icecap-sel4-hack;
  icecap-sel4-hack-meta = ./icecap/icecap-config-common/icecap-sel4-hack-meta;

  icecap-std-external = ./std-support/icecap-std-external;
  icecap-std-impl = ./std-support/icecap-std-impl;

  vmm = ./components/vmm;
  icecap-vmm-config = ./components/vmm/config;
  icecap-vmm-core = ./components/vmm/core;

  caput = ./components/caput;
  icecap-caput-config = ./components/caput/config;
  icecap-caput-types = ./components/caput/types;
  icecap-caput-host = ./components/caput/host;
  dyndl-realize = ./components/caput/dyndl-realize;
  dyndl-types = ./components/caput/dyndl-types;
  dyndl-types-derive = ./components/caput/dyndl-types/derive;

  fault-handler = ./components/fault-handler;
  icecap-fault-handler-config = ./components/fault-handler/config;

  timer-server = ./components/timer-server;
  icecap-timer-server-config = ./components/timer-server/config;

  serial-server = ./components/serial-server;
  icecap-serial-server-config = ./components/serial-server/config;

  qemu-ring-buffer-server = ./components/qemu-ring-buffer-server;
  icecap-qemu-ring-buffer-server-config = ./components/qemu-ring-buffer-server/config;

  mirage = ./components/mirage;
  icecap-linux-syscall = ./components/mirage/icecap-linux-syscall;

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
}
