{ lib, callPackage, makeOverridable'
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

  cmakeConfig = callPackage ./sel4-kernel/cmake-config.nix {};
  kernelPlat = cmakeConfig.KernelPlatform.value;

  compose = callPackage ./compose {
    _kernel = kernel;
  };

  icecapFirmware = makeOverridable' compose {};

  _sel4 = callPackage ./sel4-kernel {};
  # can be overridden individually
  kernel = _sel4;
  libsel4 = _sel4;

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
  bins = callPackage ./sel4-user/rust.nix {};
  inherit (callPackage ./sel4-user/mirage.nix {}) mkMirageBinary;

  sel4test = lib.makeScope newScope (callPackage ./sel4test {});
}
