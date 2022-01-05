{ lib, pkgs }:

lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:

let
  inherit (pkgs.dev.icecap) buildRustPackageIncrementally;
  inherit (pkgs.none.icecap) elfUtils icecapSrc platUtils;

  crates = rec {
    application = configured.callPackage ./application/crate.nix {
      inherit timer-server-types;
    };
    serial-server = configured.callPackage ./serial-server/crate.nix {};
    timer-server = configured.callPackage ./timer-server/crate.nix {
      inherit timer-server-types;
    };
    timer-server-types = configured.callPackage ./timer-server/types/crate.nix {};
  };

in rec {

  composition = configured.compose {
    action.script = icecapSrc.absoluteSplit ./cdl.py;
    config = {
      components = {
        application.image = application.split;
        serial_server.image = serial-server.split;
        timer_server.image = timer-server.split;
      };
    };
  };

  application = configured.buildIceCapComponent {
    rootCrate = crates.application;
  };

  serial-server = configured.buildIceCapComponent {
    rootCrate = crates.serial-server;
  };

  timer-server = configured.buildIceCapComponent {
    rootCrate = crates.timer-server;
  };

  run = platUtils.${configured.icecapPlat}.bundle {
    firmware = composition.image;
  };

})
