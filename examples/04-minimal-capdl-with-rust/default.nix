{ framework ? import ../../nix/framework }:

let
  inherit (framework) lib pkgs;

  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.dev.icecap) buildRustPackageIncrementally;
  inherit (pkgs.none.icecap) icecapSrc platUtils;

  crates = lib.makeScope configured.newScope (self: with self; {
    example-component = callPackage ./example-component/crate.nix {};
    example-component-config = callPackage ./example-component/config/crate.nix {};
    serialize-example-component-config = callPackage ./example-component/config/cli/crate.nix {};
  });

in rec {

  run = platUtils.${configured.icecapPlat}.bundle {
    inherit (composition) image;
  };

  composition = configured.compose {
    script = icecapSrc.absolute ./cdl.py;
    config = {
      components = {
        example_component.image = example-component.split;
      };
      tools.serialize-example-component-config = "${serialize-example-component-config}/bin/serialize-example-component-config";
    };
  };

  example-component = configured.buildIceCapComponent {
    rootCrate = crates.example-component;
  };

  serialize-example-component-config = buildRustPackageIncrementally {
    rootCrate = crates.serialize-example-component-config;
  };

}
