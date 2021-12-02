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

  buildTests = import ./build-tests.nix {
    inherit lib pkgs meta;
  };

  adHocBuildTests = import ./ad-hoc-build-tests {
    inherit lib pkgs;
  };

  docs = import ./docs {
    inherit lib pkgs meta;
  };

}
