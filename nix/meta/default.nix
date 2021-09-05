{ lib, pkgs, meta } @ topLevel:

rec {

  demos = lib.flip lib.mapAttrs (import ./demos) (_: path:
    import path { inherit lib pkgs; }
  );

  tests = lib.flip lib.mapAttrs (import ./tests) (_: path:
    lib.flip lib.mapAttrs pkgs.none.icecap.configured (_: configured:
      configured.callPackage path {
        mkInstance = mkInstance configured;
      }
    )
  );

  buildTest = import ./build-test.nix {
    inherit lib pkgs meta;
  };

  tcbSize = import ./tcb-size.nix {
    inherit pkgs;
  };

  mkInstance = import ./mk-instance.nix { inherit lib pkgs; };

}
