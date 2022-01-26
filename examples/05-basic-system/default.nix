{ framework ? import ../../nix/framework }:

let
  inherit (framework) lib pkgs;

  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.dev.icecap) buildRustPackageIncrementally;
  inherit (pkgs.none.icecap) icecapSrc platUtils;

  crates = lib.makeScope configured.newScope (self: with self; {
    application = callPackage ./components/application/crate.nix {};
    serial-server = callPackage ./components/serial-server/crate.nix {};
    timer-server = callPackage ./components/timer-server/crate.nix {};
    timer-server-types = callPackage ./components/timer-server/types/crate.nix {};
  });

in rec {

  run = platUtils.${configured.icecapPlat}.bundle {
    inherit (composition) image;
  };

  composition = configured.compose {
    script = "${icecapSrc.absolute ./cdl}/composition.py";
    config = {
      components = with components; {
        application.image = application.split;
        serial_server.image = serial-server.split;
        timer_server.image = timer-server.split;
      };
    };
  };

  components = lib.flip lib.mapAttrs crates (_: rootCrate: configured.buildIceCapComponent {
    inherit rootCrate;
  });

}
