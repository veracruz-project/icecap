{ lib, pkgs }:

let

  mkInstanceWith = import ./mk-instance.nix {
    inherit lib pkgs;
  };

  callInstance = path: args: lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:
    pkgs.none.icecap.newScope {
      inherit configured;
      mkInstance = icecapConfigOverride: mkInstanceWith {
        configured = configured.override' icecapConfigOverride;
      };
    } path args
  );

in {
  tests = {
    backtrace = callInstance ./tests/backtrace {};
  };

  inherit mkInstanceWith callInstance;
}
