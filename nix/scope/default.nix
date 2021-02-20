{ lib, buildPackages, callPackage
, linux-ng, linuxHeaders
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

  virtUtils = callPackage ./plat-utils/virt.nix {};

  globalCrates = callPackage ./crates {};

  linuxKernel = rec {
    host = byIceCapPlat (plat: callPackage (./linux-kernel/host + "/${plat}") {});
    guest = callPackage ./linux-kernel/guest {};
  };

  linuxKernelUnifiedSource = with linux-ng; doSource {
    version = "5.6.0";
    extraVersion = "-rc2";
    src = builtins.fetchGit rec {
      url = mkIceCapGitUrl "linux";
      ref = mkIceCapKeepRef rev;
      rev = "a30ea4342cbc2f7b3769eb24ad846b166a28a341";
    };
  };

  muslc = callPackage ./stdenv/musl {};
  inherit (callPackage ./stdenv {}) mkStdenv stdenvMusl stdenvBoot stdenvToken stdenvMirage;

  create-realm = callPackage ./linux-user/host/create-realm.nix {};

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

  show-backtrace = callPackage ./linux-user/dev/show-backtrace.nix {};
  append-icecap-devices = callPackage ./linux-user/dev/append-icecap-devices.nix {};
  serialize-dyndl-spec = callPackage ./linux-user/dev/serialize-dyndl-spec.nix {};
  serialize-runtime-config = callPackage ./linux-user/dev/serialize-runtime-config.nix {};

  mkSerializeConfig = callPackage ./linux-user/dev/mk-serialize-config.nix {};

  serialize-generic-config = mkSerializeConfig {
    name = "generic";
    type = "serde_json::Value";
  };
  serialize-fault-handler-config = mkSerializeConfig {
    name = "fault-handler";
    type = "icecap_fault_handler_config::Config";
    crate = globalCrates.icecap-fault-handler-config;
  };
  serialize-timer-server-config = mkSerializeConfig {
    name = "timer-server";
    type = "icecap_timer_server_config::Config";
    crate = globalCrates.icecap-timer-server-config;
  };
  serialize-serial-server-config = mkSerializeConfig {
    name = "serial-server";
    type = "icecap_serial_server_config::Config";
    crate = globalCrates.icecap-serial-server-config;
  };
  serialize-qemu-ring-buffer-server-config = mkSerializeConfig {
    name = "qemu-ring-buffer-server";
    type = "icecap_qemu_ring_buffer_server_config::Config";
    crate = globalCrates.icecap-qemu-ring-buffer-server-config;
  };
  serialize-vmm-config = mkSerializeConfig {
    name = "vmm";
    type = "icecap_vmm_config::Config";
    crate = globalCrates.icecap-vmm-config;
  };
  serialize-caput-config = mkSerializeConfig {
    name = "caput";
    type = "icecap_caput_config::Config";
    crate = globalCrates.icecap-caput-config;
  };

  patchSrc = callPackage ./nix-utils/patch-src.nix {};
  inherit (callPackage ./nix-utils/trivial-builders.nix {})
    writeShellScript emptyFile emptyDirectory;

  intToHex = callPackage ./nix-utils/int-to-hex.nix {};
  toposort = callPackage ./nix-utils/toposort {};

  mkCpio = callPackage ./nix-utils/mk-cpio.nix {};
  mkCpioFrom = callPackage ./nix-utils/mk-cpio-from.nix {};
  mkCpioObj = callPackage ./nix-utils/mk-cpio-obj.nix {};
  mkFilesObj = callPackage ./nix-utils/mk-files-obj.nix {};

  configUtils = callPackage ./nix-utils/config-utils.nix {};

}
