{ lib, pkgs }:

lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:

let
  inherit (pkgs.none.icecap) elfUtils icecapSrc platUtils;

in rec {

  composition = configured.compose {
    action.script = icecapSrc.absoluteSplit ./cdl.py;
    config = {
      components = {
        minimal.image = elfUtils.split "${minimal}/bin/minimal.elf";
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
