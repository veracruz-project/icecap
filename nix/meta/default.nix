{ lib, pkgs, meta } @ topLevel:

rec {

  demos = lib.mapAttrs (_: path: import path { inherit lib pkgs; }) (import ./demos);

  tests = import ./tests { inherit lib pkgs; };

  buildTest = import ./build-test.nix {
    inherit lib pkgs meta;
  };

  tcbSize = import ./tcb-size.nix {
    inherit pkgs;
  };

}
