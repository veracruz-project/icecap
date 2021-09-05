{ lib, pkgs }:

lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:

let
  inherit (pkgs.none.icecap) stripElfSplit icecapSrc platUtils;

in rec {

  composition = configured.compose {
    src = ./cdl;
    config = {
      components = {
        minimal.image = stripElfSplit "${minimal}/bin/minimal.elf";
      };
    };
  };

  minimal = configured.libs.mk {
    name = "minimal";
    root = icecapSrc.absoluteSplit ./minimal;
    propagatedBuildInputs = with configured.libs; [
      icecap-runtime
    ];
  };

  run = platUtils.${configured.icecapPlat}.bundle {
    firmware = composition.image;
  };

})
