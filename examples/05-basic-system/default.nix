{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.dev.icecap) buildRustPackageIncrementally;
  inherit (pkgs.none.icecap) elfUtils icecapSrc platUtils;

  crates = rec {
    application = configured.callPackage ./components/application/crate.nix {
      inherit timer-server-types;
    };
    serial-server = configured.callPackage ./components/serial-server/crate.nix {};
    timer-server = configured.callPackage ./components/timer-server/crate.nix {
      inherit timer-server-types;
    };
    timer-server-types = configured.callPackage ./components/timer-server/types/crate.nix {};
  };

in rec {

  composition = configured.compose {
    action.script = icecapSrc.extend "/composition.py" (icecapSrc.absoluteSplit ./cdl);
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

}
