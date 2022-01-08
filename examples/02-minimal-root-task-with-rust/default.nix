{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.none.icecap) icecapSrc platUtils;

in rec {

  run = platUtils.${configured.icecapPlat}.bundle {
    firmware = composition.image;
  };

  composition = configured.compose {
    app-elf = root-task.split;
  };

  root-task = configured.buildIceCapComponent {
    rootCrate = configured.callPackage ./root-task/crate.nix {};
    isRoot = true;
  };

}