{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.none.icecap) icecapSrc platUtils elfUtils;

in rec {

  run = platUtils.${configured.icecapPlat}.bundle {
    inherit (composition) image;
  };

  composition = configured.compose {
    script = icecapSrc.absolute ./cdl.py;
    config = {
      components = {
        example_component.image = elfUtils.split "${example-component}/bin/example-component.elf";
      };
    };
  };

  example-component = configured.userC.mk {
    name = "example-component";
    root = icecapSrc.absoluteSplit ./example-component;
    propagatedBuildInputs = with configured.userC.nonRootLibs; [
      icecap-runtime
      icecap-utils
    ];
  };

}
