{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.none.icecap) elfUtils icecapSrc platUtils;

in rec {

  composition = configured.compose {
    app-elf = elfUtils.split "${minimal}/bin/minimal.elf";
  };

  minimal = configured.libs.mkRoot {
    name = "minimal";
    root = icecapSrc.absoluteSplit ./minimal;
    propagatedBuildInputs = with configured.libs.root; [
      icecap-runtime
      icecap-utils
    ];
  };

  run = platUtils.${configured.icecapPlat}.bundle {
    firmware = composition.image;
  };

}
