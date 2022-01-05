{ lib, pkgs }:

let
  configured = pkgs.none.icecap.configured.virt;

  inherit (pkgs.dev) writeText;
  inherit (configured) mkMirageRealm;

in rec {
  spec = mkMirageRealm {
    inherit mirageLibrary;
    passthru = writeText "passthru.json" (builtins.toJSON {
      message = "Hello, World!";
    });
  };

  mirageLibrary = configured.callPackage ./mirage.nix {};
}
