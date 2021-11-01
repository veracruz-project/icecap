{ lib, makeOverridable'
, platUtils
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
  platformInfo = callPackage ./sel4-kernel/platform-info.nix {};

  elfloader = callPackage ./elfloader {
    libcpio = libs.cpio; # TODO ensure this is sound. Is this library properly compiled for bare-metal?
  };

  mkCapDLLoader = callPackage ./capdl/mk-capdl-loader.nix {};
  mkDynDLSpec = callPackage ./capdl/mk-dyndl-spec.nix {};
  mkIceDL = callPackage ./capdl/mk-icedl.nix {};
  mkRealm = callPackage ./capdl/mk-realm.nix {};
  mkLinuxRealm = callPackage ./capdl/mk-linux-realm.nix {};

  libs = callPackage ./sel4-user/c {};

  inherit (callPackage ./sel4-user/ocaml {}) mkMirageBinary;

  buildIceCapComponent = callPackage ./sel4-user/rust/build-icecap-component.nix {};

  bins = callPackage ./sel4-user/rust/bins.nix {};

  # TODO fix and generalize or leave up to downstream projects
  sysroot-rs = callPackage ./sel4-user/rust/sysroot.nix {};

}
