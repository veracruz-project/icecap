{ lib, pkgs, meta } @ topLevel:

let
  call = pkgs.dev.icecap.callWith topLevel;

in
rec {

  everything = call ./everything.nix {};

  # At top-level for discoverability
  examples = import ../../examples;
  demos = {
    hypervisor-demo = import ../../demos/hypervisor-demo;
  };

  tests = call ./tests {};

  generatedSources = call ./generated-sources.nix {};
  generatedDocs = call ./generated-docs {};
  adHocBuildTests = call ./ad-hoc-build-tests {};
  rustAggregate = call ./rust-aggregate {};

  tcbSize = call ./tcb-size {};

}
