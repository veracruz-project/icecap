{ lib, pkgs }:

let
  allAttrs = {
    seL4 = lib.flip lib.mapAttrs pkgs.none.icecap.configured
      (_: configured: configured.callPackage ./seL4.nix {});
    linux = lib.flip lib.mapAttrs { inherit (pkgs) dev linux musl; }
      (_: scope: scope.icecap.callPackage ./linux.nix {});
  };

in rec {
  inherit allAttrs;
} // allAttrs
