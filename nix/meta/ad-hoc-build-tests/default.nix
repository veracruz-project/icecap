{ lib, pkgs, meta }:

let
  allAttrs = lib.mapAttrs (_: lib.mapAttrs (_: v: v {
    build = true;
  })) meta.rustAggregate.allAttrs;

in
rec {

  all = pkgs.dev.writeText "ad-host-build-test-roots" (toString allList);

  allList = lib.concatMap lib.attrValues (lib.attrValues allAttrs);

} // allAttrs
