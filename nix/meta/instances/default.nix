{ lib, pkgs }:

let

  mkInstance = import ./mk-instance.nix {
    inherit lib pkgs;
  };

  commonModules = import ./common/nixos-lite-modules;

  callInstance = path: lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:
    pkgs.none.icecap.newScope {
      inherit commonModules;
      inherit configured;
      mkInstance = icecapConfigOverride: mkInstance {
        configured = configured.override' icecapConfigOverride;
      };
    } path {}
  );

in {
  tests = {
    realm-vm = callInstance ./tests/realm-vm;
    firecracker = callInstance ./tests/firecracker;
    analysis = callInstance ./tests/analysis;
    benchmark-server = callInstance ./tests/benchmark-server;
    backtrace = callInstance ./tests/backtrace;
  };
  benchmarks = {
  };
}
