{ lib, hostPlatform, callPackage }:

self: with self;

let
  superCallPackage = callPackage;
in let
  callPackage = self.callPackage;
in

superCallPackage ./rust {} self //
superCallPackage ./ocaml {} self //
{

  icecapPlats = [
    "virt"
    "rpi4"
  ];

  byIceCapPlat = f: lib.listToAttrs (map (plat: lib.nameValuePair plat (f plat)) icecapPlats);

  elaborateIceCapConfig =
    { icecapPlat, icecapPlatParams ? {}
    , profile ? "icecap", debug ? false, benchmark ? false
    }: {
      inherit icecapPlat icecapPlatParams profile debug benchmark;
    };

  configure = icecapConfig: lib.makeScope newScope (callPackage ./configured {} icecapConfig);

  configured = byIceCapPlat (icecapPlat: makeOverridable' configure (elaborateIceCapConfig {
    inherit icecapPlat;
  }));

  inherit (callPackage ./source.nix {})
    icecapSrc
    seL4EcosystemRepos
    linuxKernelUnifiedSource linuxKernelRpi4Source
    uBootUnifiedSource;

  platUtils = byIceCapPlat (plat: callPackage (./plat-utils + "/${plat}") {});

  deviceTree = callPackage ./device-tree {};

  linuxOnly = assert hostPlatform.system == "aarch64-linux"; lib.id;

  uBoot = linuxOnly {
    host = byIceCapPlat (plat: callPackage (./u-boot + "/${plat}") {});
  };

  linuxKernel = linuxOnly {
    host = byIceCapPlat (plat: callPackage (./linux-kernel/host + "/${plat}") {});
    realm = callPackage ./linux-kernel/realm {};
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

  dyndl-serialize-spec = callPackage ./dev/dyndl-serialize-spec.nix {};
  icecap-show-backtrace = callPackage ./dev/icecap-show-backtrace.nix {};
  icecap-append-devices = callPackage ./dev/icecap-append-devices.nix {};
  icecap-serialize-runtime-config = callPackage ./dev/icecap-serialize-runtime-config.nix {};
  icecap-serialize-event-server-out-index = callPackage ./dev/icecap-serialize-event-server-out-index.nix {};

  serializeConfig = callPackage ./dev/serialize-config.nix {};

  inherit (callPackage ./stdenv {}) mkStdenv stdenvMusl stdenvBoot stdenvToken stdenvMirage;

  musl = callPackage ./stdenv/musl.nix {};

  globalCrates = callPackage ./crates {};
  outerGlobalCrates = globalCrates;

  nixUtils = callPackage ./nix-utils {};
  elfUtils = callPackage ./nix-utils/elf-utils.nix {};
  cpioUtils = callPackage ./nix-utils/cpio-utils.nix {};
  cmakeUtils = callPackage ./nix-utils/cmake-utils.nix {};

  inherit (nixUtils) makeOverridable';

}
