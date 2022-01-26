{ lib, config, pkgs, meta, ... } @ topLevel:

let
  call = pkgs.dev.icecap.callWith topLevel;

in rec {

  everything = call ./everything.nix {};

  instances = call ./instances {};
  inherit (instances) tests;

  automatedTests = call ./automated-tests {};

  generatedSources = call ./generated-sources.nix {};
  generatedDocs = call ./generated-docs {};
  adHocBuildTests = call ./ad-hoc-build-tests {};
  rustAggregate = call ./rust-aggregate {};

}
