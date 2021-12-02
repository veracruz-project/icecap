{ lib, pkgs }:

rec {
  all = pkgs.dev.writeText "ad-host-build-test-roots" (toString allList);

  allList = lib.concatMap lib.attrValues [
    seL4 linux
  ];

  seL4 = lib.flip lib.mapAttrs pkgs.none.icecap.configured
    (_: configured: configured.callPackage ./seL4.nix {});
  linux = lib.flip lib.mapAttrs { inherit (pkgs) dev linux musl; }
    (_: scope: scope.icecap.callPackage ./linux.nix {});
}
