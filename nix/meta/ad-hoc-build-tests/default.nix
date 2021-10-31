{ lib, pkgs }:

rec {
  all = map lib.attrValues [ seL4 linux ];

  seL4 = lib.flip lib.mapAttrs pkgs.none.icecap.configured
    (_: configured: configured.callPackage ./seL4.nix {});
  linux = lib.flip lib.mapAttrs { inherit (pkgs) dev linux musl; }
    (_: scope: scope.icecap.callPackage ./linux.nix {});
}
