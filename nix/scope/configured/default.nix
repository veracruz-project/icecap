{ lib, makeOverridable'
, mkGlobalCrates
, stdenv
}:

icecapConfig:

self: with self;

{
  inherit icecapConfig;
  inherit (icecapConfig) icecapPlat;

  selectIceCapPlat = attrs: attrs.${icecapPlat};
  selectIceCapPlatOr = default: attrs: attrs.${icecapPlat} or default;

  compose = callPackage ./compose {};

  icecapFirmware = makeOverridable' compose {};

  # TODO unify with parent scope deviceTree attribute
  deviceTreeConfigured = callPackage ./device-tree {};

  cmakeConfig = callPackage ./sel4-kernel/cmake-config.nix {};

  kernel = makeOverridable' (callPackage ./sel4-kernel {}) {};
  libsel4 = kernel;

  object-sizes = callPackage ./sel4-kernel/object-sizes.nix {};

  elfloader = callPackage ./elfloader {
    libcpio = libs.cpio; # TODO ensure this is sound. Is this library properly compiled for bare metal?
  };

  capdl-loader-lib = callPackage ./capdl/capdl-loader-lib.nix {};
  mkCapDLLoader = callPackage ./capdl/mk-capdl-loader.nix {};
  mkDynDLSpec = callPackage ./capdl/mk-dyndl-spec.nix {};
  mkIceDL = callPackage ./capdl/mk-icedl.nix {};

  # TODO does this belong here?
  mkLinuxRealm = callPackage ./capdl/mk-linux-realm {};

  stdenvIceCap = mkStdenv (callPackage ./sel4-user/c/libc-wrapper.nix {});

  libs = callPackage ./sel4-user/c {};
  bins = callPackage ./sel4-user/rust/bins.nix {};
  inherit (callPackage ./sel4-user/mirage.nix {}) mkMirageBinary;

  globalCrates = mkGlobalCrates {
    seL4 = true;
    inherit (icecapConfig) benchmark;
    extraArgs = {
      inherit stdenv icecap-sel4-sys-gen;
    };
  };

  icecap-sel4-sys-gen = callPackage ./sel4-user/rust/icecap-sel4-sys-gen {};
  inherit (icecap-sel4-sys-gen) liboutline;

  sysroot-rs = callPackage ./sel4-user/rust/sysroot.nix {
    # HACK wasmtime violates some assertions in core
    release = true;
  };

  buildIceCapCrate = callPackage ./sel4-user/rust/build-icecap-crate.nix {};

}
