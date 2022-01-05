{ lib, pkgs, meta } @ topLevel:

let
  call = pkgs.dev.icecap.callWith topLevel;

in
rec {

  tcbSize = call ./tcb-size {};

  generatedSources = call ./generated-sources.nix {};

  # At top-level for discoverability
  examples = import ../../examples;
  demos = import ../../demos;

  tests = call ./tests {};

  buildTests = call ./build-tests.nix {};

  rustAggregate = call ./rust-aggregate {};

  adHocBuildTests = call ./ad-hoc-build-tests {};

  generatedDocs = call ./generated-docs {};

}
