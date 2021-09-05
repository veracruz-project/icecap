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

  inherit (callPackage ./source.nix {})
    icecapSrc
    seL4EcosystemRepos
    linuxKernelUnifiedSource uBootUnifiedSource
    ;

  deviceTree = callPackage ./device-tree {};

  # TODO distinguish between interface and unique
  platUtils = byIceCapPlat (plat: callPackage (./plat-utils + "/${plat}") {});
  virtUtils = platUtils.virt;
  rpi4Utils = platUtils.rpi4;

  mkGlobalCrates = callPackage ./crates {};
  outerGlobalCrates = mkGlobalCrates {};

  muslc = callPackage ./stdenv/musl {};
  inherit (callPackage ./stdenv {}) mkStdenv stdenvMusl stdenvBoot stdenvToken stdenvMirage;

  uBoot = assert hostPlatform.system == "aarch64-linux"; { # HACK
    host = byIceCapPlat (plat: callPackage (./u-boot + "/${plat}") {});
  };

  linuxKernel = assert hostPlatform.system == "aarch64-linux"; { # HACK
    host = byIceCapPlat (plat: callPackage (./linux-kernel/host + "/${plat}") {});
    guest = callPackage ./linux-kernel/guest {};
  };

  nixosLite = callPackage ./linux-user/nixos-lite {};

  icecap-host = callPackage ./linux-user/icecap-host.nix {};
  crosvm-9p-server = callPackage ./linux-user/crosvm-9p-server.nix {};

  firecracker = callPackage ./linux-user/firecracker/firecracker.nix {};
  firecracker-prebuilt = callPackage ./linux-user/firecracker/firecracker-prebuilt.nix {};
  firectl = callPackage ./linux-user/firecracker/firectl.nix {};
  libfdt = callPackage ./linux-user/firecracker/libfdt {};

  capdl-tool = callPackage ./dev/capdl-tool.nix {};
  sel4-manual = callPackage ./dev/sel4-manual.nix {};

  icecap-show-backtrace = callPackage ./dev/icecap-show-backtrace.nix {};
  icecap-append-devices = callPackage ./dev/icecap-append-devices.nix {};
  dyndl-serialize-spec = callPackage ./dev/dyndl-serialize-spec.nix {};
  icecap-serialize-runtime-config = callPackage ./dev/icecap-serialize-runtime-config.nix {};

  serializeConfig = callPackage ./dev/serialize-config.nix {};

  elfUtils = callPackage ./nix-utils/elf-utils.nix {};
  cpioUtils = callPackage ./nix-utils/cpio-utils.nix {};
  cmakeUtils = callPackage ./nix-utils/cmake-utils.nix {};

}
