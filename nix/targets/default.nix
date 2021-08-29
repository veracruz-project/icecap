let
  pkgs = import ../.;
in

rec {
  inherit pkgs;

  instances = pkgs.none.icecap.callPackage ../instances {};

  buildTest = import ./build-test.nix {
    inherit pkgs instances;
  };

  tcbSize = import ./tcb-size.nix {
    inherit pkgs;
  };
}
