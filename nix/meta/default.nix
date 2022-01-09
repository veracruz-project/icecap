{ lib, config, pkgs, meta } @ topLevel:

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

  instances = call ./instances {};
  inherit (instances) tests benchmarks hacking;

  generatedSources = call ./generated-sources.nix {};
  generatedDocs = call ./generated-docs {};
  adHocBuildTests = call ./ad-hoc-build-tests {};
  rustAggregate = call ./rust-aggregate {};

  tcbSize = call ./tcb-size {};

  display = call ./display.nix {};

}
