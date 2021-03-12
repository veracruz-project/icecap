{ lib, callPackage
}:

config:

let
  superCallPackage = callPackage;
in

self: with self;

let
  callPackage = self.callPackage;
in

superCallPackage ./rust {} self //
{
  inherit config;

  icecapPlat = config.plat;
  selectIceCapPlat = attrs: attrs.${icecapPlat};

  cmakeConfig = callPackage ./cmake-config.nix {};
  kernelPlat = cmakeConfig.KernelPlatform.value;

  inherit (callPackage ./icecap {}) compose icecapFirmware mkIceDL;

  _sel4 = callPackage ./sel4-kernel {};
  # can be overridden individually
  kernel = _sel4;
  libsel4 = _sel4;

  object-sizes = callPackage ./sel4-kernel/object-sizes.nix {};

  elfloader = callPackage ./elfloader {
    # HACK
    inherit (sel4test) runCMake;
    inherit (sel4test.remoteLibs) libcpio;
  };

  capdl-loader-lib = callPackage ./capdl/capdl-loader-lib.nix {};
  mkCapDLLoader = callPackage ./capdl/mk-capdl-loader.nix {};
  mkDynDLSpec = callPackage ./capdl/mk-dyndl-spec.nix {};

  stdenvIceCap = mkStdenv (callPackage ./sel4-user/c/libc-wrapper.nix {});

  libs = callPackage ./sel4-user/c {};
  bins = callPackage ./sel4-user/rust.nix {};
  inherit (callPackage ./sel4-user/mirage.nix {}) mkMirageBinary;

  sel4test = lib.makeScope newScope (callPackage ./sel4test {});
}
