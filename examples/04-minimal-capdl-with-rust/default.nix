{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.dev.icecap) buildRustPackageIncrementally;
  inherit (pkgs.none.icecap) elfUtils icecapSrc platUtils;

  crates = rec {
    example-component-config = configured.callPackage ./example-component/config/crate.nix {};
    example-component = configured.callPackage ./example-component/crate.nix {
      inherit example-component-config;
    };
    serialize-example-component-config = configured.callPackage ./example-component/config/cli/crate.nix {
      inherit example-component-config;
    };
  };

in rec {

  composition = configured.compose {
    action.script = icecapSrc.absoluteSplit ./cdl.py;
    config = {
      components = {
        example_component.image = example-component.split;
      };
      tools.serialize-example-component-config = "${serialize-example-component-config}/bin/serialize-example-component-config";
    };
  };

  example-component = configured.buildIceCapComponent {
    rootCrate = crates.example-component;
    debug = true;
  };

  serialize-example-component-config = buildRustPackageIncrementally {
    rootCrate = crates.serialize-example-component-config;
    layers =  [ [] ];
  };

  run = platUtils.${configured.icecapPlat}.bundle {
    firmware = composition.image;
  };

}
