{ lib, pkgs, meta } @ topLevel:

rec {

  tcbSize = import ./tcb-size.nix {
    inherit lib pkgs;
  };

  generate = import ./generate.nix {
    inherit lib pkgs;
  };

  # At top-level for discoverability
  examples = import ../../examples;
  demos = import ../../demos;

  tests = import ./tests {
    inherit lib pkgs;
  };

  buildTests = import ./build-tests.nix {
    inherit lib pkgs meta;
  };

  rust = import ./rust {
    inherit lib pkgs;
  };

  adHocBuildTests = import ./ad-hoc-build-tests {
    inherit lib pkgs meta;
  };

  docs = import ./docs {
    inherit lib pkgs meta;
  };

}
