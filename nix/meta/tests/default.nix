{ lib, pkgs }:

let

  mkTest = import ./mk-test.nix {
    inherit lib pkgs;
  };

  commonModules = import ./common/nixos-lite-modules;

  callTest = path: lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:
    pkgs.none.icecap.newScope {
      inherit commonModules;
      inherit configured;
      mkTest = icecapConfigOverride: mkTest {
        configured = configured.override' icecapConfigOverride;
      };
    } path {}
  );

in {
  realm-vm = callTest ./realm-vm;
  firecracker = callTest ./firecracker;
  analysis = callTest ./analysis;
  benchmark-utilisation = callTest ./benchmark-utilisation;
  backtrace = callTest ./backtrace;
}
