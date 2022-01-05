{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.dev.icecap) buildRustPackageIncrementally;
  inherit (pkgs.none.icecap) elfUtils icecapSrc platUtils;

  crates = rec {
    minimal-config = configured.callPackage ./minimal/config/crate.nix {};
    minimal = configured.callPackage ./minimal/crate.nix {
      inherit minimal-config;
    };
    serialize-minimal-config = configured.callPackage ./minimal/config/cli/crate.nix {
      inherit minimal-config;
    };
  };

in rec {

  composition = configured.compose {
    action.script = icecapSrc.absoluteSplit ./cdl.py;
    config = {
      components = {
        minimal.image = minimal.split;
      };
      tools.serialize-minimal-config = "${serialize-minimal-config}/bin/serialize-minimal-config";
    };
  };

  minimal = configured.buildIceCapComponent {
    rootCrate = crates.minimal;
    debug = true;
  };

  serialize-minimal-config = buildRustPackageIncrementally {
    rootCrate = crates.serialize-minimal-config;
    layers =  [ [] ];
    debug = true;
  };

  run = platUtils.${configured.icecapPlat}.bundle {
    firmware = composition.image;
  };

}
