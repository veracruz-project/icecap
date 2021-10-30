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

  mkTool = rootCrate: buildRustPackageIncrementally {
    inherit rootCrate;
    layers =  [ [] ];
    debug = true;
  };

  dyndl-serialize-spec = mkTool globalCrates.dyndl-serialize-spec;
  icecap-show-backtrace = mkTool globalCrates.icecap-show-backtrace;
  icecap-append-devices = mkTool globalCrates.icecap-append-devices;
  icecap-serialize-runtime-config = mkTool globalCrates.icecap-serialize-runtime-config;
  icecap-serialize-builtin-config = mkTool globalCrates.icecap-serialize-builtin-config;
  icecap-serialize-event-server-out-index = mkTool globalCrates.icecap-serialize-event-server-out-index;

  inherit (callPackage ./stdenv {}) mkStdenv stdenvMusl stdenvBoot stdenvToken stdenvMirage;

  musl = callPackage ./stdenv/musl.nix {};

  globalCrates = callPackage ./crates {};
  generatedCrateManifests = callPackage ./crates/generate {};

  nixUtils = callPackage ./nix-utils {};
  elfUtils = callPackage ./nix-utils/elf-utils.nix {};
  cpioUtils = callPackage ./nix-utils/cpio-utils.nix {};
  cmakeUtils = callPackage ./nix-utils/cmake-utils.nix {};

  inherit (nixUtils) makeOverridable';

}
