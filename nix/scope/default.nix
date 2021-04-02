{ lib, buildPackages, callPackage
, uboot-ng, linux-ng, linuxHeaders
, busybox
}:

self: with self;

let
  superCallPackage = callPackage;
in let
  callPackage = self.callPackage;
in

superCallPackage ./rust {} self //
superCallPackage ./ocaml {} self //
{

  # TODO callPackage uses makeOverridable, which is not desirable here.
  configure = icecapConfig: lib.makeScope newScope (callPackage ./configured {} icecapConfig);

  # HACK
  configured = byIceCapPlat (plat: configure {
    inherit plat;
    profile = "icecap";
  }) // {
    sel4test = byIceCapPlat (plat: configure {
      inherit plat;
      profile = "sel4test";
    });
  };

  # HACK
  runPkgs = buildPackages;

  # TODO name
  repos = callPackage ./source.nix {};
  inherit (repos) mkIceCapGitUrl mkIceCapKeepRef mkIceCapLocalPath mkIceCapSrc;

  mkTrivialSrc = store: { inherit store; env = store; };
  mkAbsSrc = path: { store = lib.cleanSource path; env = toString path; };

  icecapSrcRel = suffix: (icecapSrcRelSplit suffix).store;
  icecapSrcAbs = src: (icecapSrcAbsSplit src).store;
  icecapSrcRelRaw = suffix: ../../src + "/${suffix}";
  icecapSrcFilter = name: type: true; # TODO
  icecapSrcRelSplit = suffix: icecapSrcAbsSplit (icecapSrcRelRaw suffix);
  icecapSrcAbsSplit = src: {
    store = lib.cleanSourceWith {
      src = lib.cleanSource src;
      filter = icecapSrcFilter;
    };
    env = toString src;
  };

  icecapPlats = [
    "virt"
    "rpi4"
  ];

  byIceCapPlat = f: lib.listToAttrs (map (plat: { name = plat; value = f plat; }) icecapPlats);

  deviceTree = callPackage ./device-tree {};

  virtUtils = callPackage ./plat-utils/virt {};
  rpi4Utils = callPackage ./plat-utils/rpi4 {};

  mkGlobalCrates = callPackage ./crates {};
  outerGlobalCrates = mkGlobalCrates {};

  uBoot = byIceCapPlat (plat: callPackage (./u-boot + "/${plat}") {});

  uBootUnifiedSource = with uboot-ng; doSource {
    version = "2019.07";
    src = (mkIceCapSrc {
      repo = "u-boot";
      rev = "9626efe72a2200d3dc6852ce41e4c34f791833bf"; # branch icecap-host
    }).store;
  };

  linuxKernel = rec {
    host = byIceCapPlat (plat: callPackage (./linux-kernel/host + "/${plat}") {});
    guest = callPackage ./linux-kernel/guest {};
  };

  linuxKernelUnifiedSource = with linux-ng; doSource {
    version = "5.6.0";
    extraVersion = "-rc2";
    src = (mkIceCapSrc {
      repo = "linux";
      rev = "9ee126e256066b2c22ea75296b79ce0bc1a4af94"; # branch icecap
    }).store;
  };

  muslc = callPackage ./stdenv/musl {};
  inherit (callPackage ./stdenv {}) mkStdenv stdenvMusl stdenvBoot stdenvToken stdenvMirage;

  icecap-host = callPackage ./linux-user/host/icecap-host.nix {};

  firecracker = callPackage ./linux-user/host/firecracker.nix {};
  firecracker-prebuilt = callPackage ./linux-user/host/firecracker-prebuilt.nix {};
  firectl = callPackage ./linux-user/host/firectl.nix {};

  libfdt = callPackage ./linux-user/libfdt/default.nix {};
  _9p-server = callPackage ./linux-user/9p-server {};

  busybox-static = busybox.override {
    enableStatic = true;
    useMusl = true;
  };

  capdl-tool = callPackage ./linux-user/dev/capdl-tool.nix {};
  sel4-manual = callPackage ./sel4-manual {};

  icecap-show-backtrace = callPackage ./linux-user/dev/icecap-show-backtrace.nix {};
  icecap-append-devices = callPackage ./linux-user/dev/icecap-append-devices.nix {};
  dyndl-serialize-spec = callPackage ./linux-user/dev/dyndl-serialize-spec.nix {};
  icecap-serialize-runtime-config = callPackage ./linux-user/dev/icecap-serialize-runtime-config.nix {};

  mkSerializeConfig = callPackage ./linux-user/dev/mk-serialize-config.nix {};

  serialize-generic-config = mkSerializeConfig {
    name = "generic";
    type = "serde_json::Value";
  };
  serialize-fault-handler-config = mkSerializeConfig {
    name = "fault-handler";
    type = "icecap_fault_handler_config::Config";
    crate = outerGlobalCrates.icecap-fault-handler-config;
  };
  serialize-timer-server-config = mkSerializeConfig {
    name = "timer-server";
    type = "icecap_timer_server_config::Config";
    crate = outerGlobalCrates.icecap-timer-server-config;
  };
  serialize-serial-server-config = mkSerializeConfig {
    name = "serial-server";
    type = "icecap_serial_server_config::Config";
    crate = outerGlobalCrates.icecap-serial-server-config;
  };
  serialize-qemu-ring-buffer-server-config = mkSerializeConfig {
    name = "qemu-ring-buffer-server";
    type = "icecap_qemu_ring_buffer_server_config::Config";
    crate = outerGlobalCrates.icecap-qemu-ring-buffer-server-config;
  };
  serialize-vmm-config = mkSerializeConfig {
    name = "vmm";
    type = "icecap_host_vmm_config::Config";
    crate = outerGlobalCrates.icecap-host-vmm-config;
  };
  serialize-resource-server-config = mkSerializeConfig {
    name = "resource-server";
    type = "icecap_resource_server_config::Config";
    crate = outerGlobalCrates.icecap-resource-server-config;
  };

  patchSrc = callPackage ./nix-utils/patch-src.nix {};
  inherit (callPackage ./nix-utils/trivial-builders.nix {})
    writeShellScript emptyFile emptyDirectory;

  intToHex = callPackage ./nix-utils/int-to-hex.nix {};
  toposort = callPackage ./nix-utils/toposort {};

  stripElf = callPackage ./nix-utils/strip-elf.nix {};
  stripElfSplit = callPackage ./nix-utils/strip-elf-split.nix {};
  stripElfSplitTrivial = callPackage ./nix-utils/strip-elf-split-trivial.nix {};

  mkCpio = callPackage ./nix-utils/mk-cpio.nix {};
  mkCpioFrom = callPackage ./nix-utils/mk-cpio-from.nix {};
  mkCpioObj = callPackage ./nix-utils/mk-cpio-obj.nix {};
  mkFilesObj = callPackage ./nix-utils/mk-files-obj.nix {};

  configUtils = callPackage ./nix-utils/config-utils.nix {};

}
