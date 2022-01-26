{ lib, pkgs, framework }:

let
  commonModules = import ./common/nixos-lite-modules;

  callInstance = path: args: lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:
    pkgs.none.icecap.newScope {
      inherit commonModules;
      inherit configured;
      mkInstance = icecapConfigOverride:
        let
          configured' = configured.override' icecapConfigOverride;
        in f: framework.instances.mkInstanceWith {
          configured = configured';
        } (self: {
         composition = configured'.icecapFirmware;
        });
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
    example = callInstance ./hacking/example {};
  };
}
