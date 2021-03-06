{ lib, hostPlatform, callPackage, icecapFramework, linuxHelpers, splicePackages }:

let
  superCallPackage = callPackage;
in

self:

let
  callPackage = self.callPackage;
in

# Add nonePkgs, devPkgs, etc. to scope.
lib.mapAttrs' (k: lib.nameValuePair "${k}Pkgs") icecapFramework.pkgs //

# To avoid clutter, distribute scope accross multiple files.
superCallPackage ./rust {} self //

(with self; {

  icecapFrameworkConfig = icecapFramework.config;

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

  configure = icecapConfig: (lib.makeScope newScope (callPackage ./configured {} icecapConfig)).overrideScope' overrideConfiguredScope;

  overrideConfiguredScope = self: super: {};

  configured = byIceCapPlat (icecapPlat: makeOverridable' configure (elaborateIceCapConfig {
    inherit icecapPlat;
  }));

  inherit (callPackage ./source.nix {}) icecapSrc icecapExternalSrc;

  platUtils = byIceCapPlat (plat: callPackage (./plat-utils + "/${plat}") {});

  linuxOnly = assert hostPlatform.system == "aarch64-linux"; lib.id;

  uBoot = linuxOnly {
    host = byIceCapPlat (plat: callPackage (./u-boot + "/${plat}") {});
  };

  linuxKernel = linuxOnly {
    host = byIceCapPlat (plat: callPackage (./linux-kernel/host + "/${plat}") {});
    guest.minimal = callPackage ./linux-kernel/guest/minimal {};
  };

  nixosLite = callPackage ./linux-user/nixos-lite {};

  crosvm-9p-server = callPackage ./linux-user/crosvm-9p-server.nix {};

  capdl-tool = callPackage ./dev/capdl-tool.nix {};
  sel4-manual = callPackage ./dev/sel4-manual.nix {};

  mkTool = rootCrate: buildRustPackageIncrementally {
    inherit rootCrate;
    debug = true; # speed up build
  };

  dyndl-serialize-spec = mkTool globalCrates.dyndl-serialize-spec;
  icecap-show-backtrace = mkTool globalCrates.icecap-show-backtrace;
  icecap-serialize-runtime-config = mkTool globalCrates.icecap-serialize-runtime-config;
  icecap-serialize-generic-component-config = mkTool globalCrates.icecap-serialize-generic-component-config;

  inherit (callPackage ./stdenv {}) mkStdenv stdenvMusl stdenvBoot stdenvToken stdenvMirage;

  musl = callPackage ./stdenv/musl.nix {};

  globalCrates = callPackage ./crates {};
  generatedCrateManifests = callPackage ./crates/generate {};

  nixUtils = callPackage ./nix-utils {};
  elfUtils = callPackage ./nix-utils/elf-utils.nix {};
  cpioUtils = callPackage ./nix-utils/cpio-utils.nix {};
  cmakeUtils = callPackage ./nix-utils/cmake-utils.nix {};

  inherit (nixUtils) callWith makeOverridable';

  # Re-export for convenience
  inherit (linuxHelpers) dtbHelpers raspios raspberry-pi-firmare;

  # Relegate ocaml to sub-scope
  ocamlScope =
    let
      superOtherSplices = otherSplices;
    in
    let
      otherSplices = with superOtherSplices; {
        selfBuildBuild = selfBuildBuild.ocamlScope;
        selfBuildHost = selfBuildHost.ocamlScope;
        selfBuildTarget = selfBuildTarget.ocamlScope;
        selfHostHost = selfHostHost.ocamlScope;
        selfTargetTarget = selfTargetTarget.ocamlScope or {};
      };
    in
      lib.makeScopeWithSplicing
        splicePackages
        newScope
        otherSplices
        (_: {})
        (_: {})
        (self: callPackage ./ocaml {} self // {
          __dontRecurseWhenSplicing = true; # recursing breaks attribute sets whose keys depend on the offset
          inherit superOtherSplices otherSplices; # for convenience
        })
      ;

  inherit (ocamlScope) icecap-ocaml-runtime;
})
