{ lib, pkgs, meta } @ topLevel:

rec {

  demos = lib.flip lib.mapAttrs (import ./demos) (_: path:
    import path { inherit lib pkgs; }
  );

  tests = import ./tests {
    inherit lib pkgs;
  };

  buildTest = import ./build-test.nix {
    inherit lib pkgs meta;
  };

  tcbSize = import ./tcb-size.nix {
    inherit lib pkgs;
  };

}
