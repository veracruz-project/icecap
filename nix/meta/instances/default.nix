{ lib, pkgs }:

let

  mkInstance = import ./mk-instance.nix {
    inherit lib pkgs;
  };

  commonModules = import ./common/nixos-lite-modules;

  callInstance = path: args: lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:
    pkgs.none.icecap.newScope {
      inherit commonModules;
      inherit configured;
      mkInstance = icecapConfigOverride: mkInstance {
        configured = configured.override' icecapConfigOverride;
      };
    } path args
  );

in {
  tests = {
    hypervisor = callInstance ./tests/hypervisor {};
    benchmark-server = callInstance ./tests/benchmark-server {};
    backtrace = callInstance ./tests/backtrace {};
  };
  benchmarks = {
    hypervisor = callInstance ./benchmarks/hypervisor {};
    hypervisor-with-utilization = callInstance ./benchmarks/hypervisor { withUtilization = true; };
    firecracker = callInstance ./benchmarks/firecracker {};
  };
  hacking = {
    hypervisor = callInstance ./hacking/hypervisor {};
  };
}
