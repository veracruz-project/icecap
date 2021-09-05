{ lib, buildPackages, callPackage
, hostPlatform
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

  configured = byIceCapPlat (plat: configure {
    inherit plat;
    debug = false;
    benchmark = true;
    # benchmark = false;
    profile = "icecap";
  });

  icecapPlats = [
    "virt"
    "rpi4"
  ];

  byIceCapPlat = f: lib.listToAttrs (map (plat: { name = plat; value = f plat; }) icecapPlats);

  # TODO name
  repos = callPackage ./source.nix {};
  inherit (repos)
    mkIceCapGitUrl mkIceCapKeepRef mkIceCapLocalPath mkIceCapSrc
    icecapSrcRel
    icecapSrcAbs
    icecapSrcRelRaw
    icecapSrcFilter
    icecapSrcRelSplit
    icecapSrcAbsSplit
    mkAbsSrc mkTrivialSrc
    linuxKernelUnifiedSource uBootUnifiedSource
    ;

  deviceTree = callPackage ./device-tree {};

  # TODO distinguish between interface and unique
  platUtils = byIceCapPlat (plat: callPackage (./plat-utils + "/${plat}") {});
  virtUtils = platUtils.virt;
  rpi4Utils = platUtils.rpi4;

  mkGlobalCrates = callPackage ./crates {};
  outerGlobalCrates = mkGlobalCrates {};

  uBoot =
    assert hostPlatform.system == "aarch64-linux"; # HACK
    byIceCapPlat (plat: callPackage (./u-boot + "/${plat}") {});

  linuxKernel = assert hostPlatform.system == "aarch64-linux"; { # HACK
    host = byIceCapPlat (plat: callPackage (./linux-kernel/host + "/${plat}") {});
    guest = callPackage ./linux-kernel/guest {};
  };

  muslc = callPackage ./stdenv/musl {};
  inherit (callPackage ./stdenv {}) mkStdenv stdenvMusl stdenvBoot stdenvToken stdenvMirage;

  icecap-host = callPackage ./linux-user/host/icecap-host.nix {};

  firecracker = callPackage ./linux-user/host/firecracker.nix {};
  firecracker-prebuilt = callPackage ./linux-user/host/firecracker-prebuilt.nix {};
  firectl = callPackage ./linux-user/host/firectl.nix {};

  libfdt = callPackage ./linux-user/libfdt/default.nix {};
  _9p-server = callPackage ./linux-user/9p-server {};

  nixosLite = callPackage ./linux-user/nixos-lite {};

  capdl-tool = callPackage ./linux-user/dev/capdl-tool.nix {};
  sel4-manual = callPackage ./sel4-manual {};

  icecap-show-backtrace = callPackage ./linux-user/dev/icecap-show-backtrace.nix {};
  icecap-append-devices = callPackage ./linux-user/dev/icecap-append-devices.nix {};
  dyndl-serialize-spec = callPackage ./linux-user/dev/dyndl-serialize-spec.nix {};
  icecap-serialize-runtime-config = callPackage ./linux-user/dev/icecap-serialize-runtime-config.nix {};

  serializeConfig = callPackage ./linux-user/dev/serialize-config.nix {};

  patchSrc = callPackage ./nix-utils/patch-src.nix {};
  inherit (callPackage ./nix-utils/trivial-builders.nix {})
    writeShellScript emptyFile emptyDirectory;

  stripElf = callPackage ./nix-utils/strip-elf.nix {};
  stripElfSplit = callPackage ./nix-utils/strip-elf-split.nix {};
  stripElfSplitTrivial = callPackage ./nix-utils/strip-elf-split-trivial.nix {};

  mkCpio = callPackage ./nix-utils/mk-cpio.nix {};
  mkCpioFrom = callPackage ./nix-utils/mk-cpio-from.nix {};
  mkCpioObj = callPackage ./nix-utils/mk-cpio-obj.nix {};

  configUtils = callPackage ./nix-utils/config-utils.nix {};

}
