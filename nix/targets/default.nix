pkgs:

rec {
  inherit pkgs;

  configured = pkgs.none.icecap.byIceCapPlat (plat: pkgs.none.icecap.configure {
    inherit plat;
    profile = "icecap";
  });

  instances = pkgs.none.icecap.callPackage ../instances {};

  buildTest = import ./build-test.nix {
    inherit pkgs configured instances;
  };

  tcbSize = import ./tcb-size.nix {
    inherit pkgs configured;
  };
}
