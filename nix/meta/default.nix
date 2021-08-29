{ lib, pkgs, ... }:

rec {
  instances = pkgs.none.icecap.callPackage ../instances {};

  buildTest = import ./build-test.nix {
    inherit lib pkgs instances;
  };

  tcbSize = import ./tcb-size.nix {
    inherit pkgs;
  };
}
