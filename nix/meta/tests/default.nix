{ lib, pkgs }:

let

  mkTest = import ./mk-test.nix {
    inherit lib pkgs;
  };

  paths = {
    realm-vm = ./realm-vm;
    firecracker = ./firecracker;
    analysis = ./analysis;
    benchmark-utilisation = ./benchmark-utilisation;
    backtrace = ./backtrace;
  };

in
lib.flip lib.mapAttrs paths (_: path:
  lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:
    pkgs.none.icecap.callPackage path {
      mkInstance = icecapConfigOverride: mkTest {
        configured = configured.override' icecapConfigOverride;
      };
    }
  )
)
