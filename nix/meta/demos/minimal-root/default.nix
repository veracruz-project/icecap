{ lib, pkgs }:

lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:

let
  inherit (pkgs.none.icecap) stripElfSplit icecapSrcAbsSplit platUtils;

in rec {

  composition = configured.compose {
    app-elf = stripElfSplit "${minimal}/bin/minimal.elf";
  };

  minimal = configured.libs.mkRoot {
    name = "minimal";
    root = icecapSrcAbsSplit ./minimal;
    propagatedBuildInputs = with configured.libs; [
      icecap-runtime-root
      icecap-utils
    ];
  };

  run = platUtils.${configured.icecapPlat}.bundle {
    firmware = composition.image;
  };

})
