{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.none.icecap) elfUtils icecapSrc platUtils;

in rec {

  composition = configured.compose {
    app-elf = minimal.split;
  };

  minimal = configured.buildIceCapComponent {
    rootCrate = configured.callPackage ./minimal/crate.nix {};
    isRoot = true;
    debug = true;
  };

  run = platUtils.${configured.icecapPlat}.bundle {
    firmware = composition.image;
  };

}
