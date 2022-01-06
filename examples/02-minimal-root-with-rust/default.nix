{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.none.icecap) elfUtils icecapSrc platUtils;

in rec {

  composition = configured.compose {
    app-elf = root-task.split;
  };

  root-task = configured.buildIceCapComponent {
    rootCrate = configured.callPackage ./root-task/crate.nix {};
    isRoot = true;
  };

  run = platUtils.${configured.icecapPlat}.bundle {
    firmware = composition.image;
  };

}
