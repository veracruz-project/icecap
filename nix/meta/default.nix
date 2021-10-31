{ lib, pkgs, meta } @ topLevel:

rec {

  tcbSize = import ./tcb-size.nix {
    inherit lib pkgs;
  };

  generate = import ./generate.nix {
    inherit lib pkgs;
  };

  demos = lib.flip lib.mapAttrs (import ./demos) (_: path:
    import path { inherit lib pkgs; }
  );

  tests = import ./tests {
    inherit lib pkgs;
  };

  buildTest = import ./build-test.nix {
    inherit lib pkgs meta;
  };

  adHocBuildTests = import ./ad-hoc-build-tests {
    inherit lib pkgs;
  };

}
