{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.none.icecap) elfUtils icecapSrc platUtils;

in rec {

  composition = configured.compose {
    action.script = icecapSrc.absoluteSplit ./cdl.py;
    config = {
      components = {
        example_component.image = elfUtils.split "${example-component}/bin/example-component.elf";
      };
    };
  };

  example-component = configured.libs.mk {
    name = "example-component";
    root = icecapSrc.absoluteSplit ./example-component;
    propagatedBuildInputs = with configured.libs; [
      icecap-runtime
    ];
  };

  run = platUtils.${configured.icecapPlat}.bundle {
    firmware = composition.image;
  };

}
