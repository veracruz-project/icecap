{ lib, pkgs, meta } @ topLevel:

rec {
  instances = pkgs.none.icecap.callPackage ../instances {};

  buildTest = import ./build-test.nix {
    inherit lib pkgs meta;
  };

  tcbSize = import ./tcb-size.nix {
    inherit pkgs;
  };

  demos = lib.mapAttrs (_: path: import path { inherit lib pkgs; }) (import ./demos);
}
