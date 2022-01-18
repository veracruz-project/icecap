{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.none.icecap) icecapSrc platUtils;
  inherit (configured) mkIceDL mkDynDLSpec;

  crates = lib.makeScope configured.newScope (self: with self; {
    supercomponent = callPackage ./crates/supercomponent/crate.nix {};
    subcomponent = callPackage ./crates/subcomponent/crate.nix {};
  });

in rec {

  run = platUtils.${configured.icecapPlat}.bundle {
    firmware = composition.image;
  };

  composition = configured.compose {
    action.script = icecapSrc.absoluteSplit ./supersystem.py;
    config = {
      components = {
        supercomponent.image = components.supercomponent.split;
      };
      subsystem_spec = serializedSubsystem;
    };
  };

  subsystem = mkIceDL {
    action.script = icecapSrc.absoluteSplit ./subsystem.py;
    config = {
      num_cores = 1;
      components = {
        subcomponent.image = components.subcomponent.split;
      };
    };
  };

  serializedSubsystem = mkDynDLSpec {
    cdl = "${subsystem}/icecap.cdl";
    root = "${subsystem}/links";
  };

  components = lib.flip lib.mapAttrs crates (_: rootCrate: configured.buildIceCapComponent {
    inherit rootCrate;
  });

}
