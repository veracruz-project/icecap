{ lib, pkgs }:

let

  mkTest = import ./mk-test.nix {
    inherit lib pkgs;
  };

  callTest = path: lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:
    pkgs.none.icecap.newScope {
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
