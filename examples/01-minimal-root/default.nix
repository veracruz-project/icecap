{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.none.icecap) elfUtils icecapSrc platUtils;

in rec {

  composition = configured.compose {
    app-elf = elfUtils.split "${root-task}/bin/root-task.elf";
  };

  root-task = configured.libs.mkRoot {
    name = "root-task";
    root = icecapSrc.absoluteSplit ./root-task;
    propagatedBuildInputs = with configured.libs.root; [
      icecap-runtime
      icecap-utils
    ];
  };

  run = platUtils.${configured.icecapPlat}.bundle {
    firmware = composition.image;
  };

}
