{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.dev) writeText;
  inherit (configured) mkMirageRealm;

in rec {
  spec = mkMirageRealm {
    inherit mirageLibrary;
    passthru = writeText "passthru.json" (builtins.toJSON {
      network_config = {
        mac = "00:0a:95:9d:68:16";
        ip = "192.168.1.2";
        network = "192.168.1.0/24";
        gateway = "192.168.1.1";
      };
    });
  };

  mirageLibrary = pkgs.none.icecap.ocamlScope.callPackage ./mirage.nix {};
}
