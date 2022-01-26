self: with self;

let
  call = pkgs.dev.icecap.callWith self;

in {

  everything = call ./everything.nix {};

  instances = call ./instances {};
  inherit (instances) tests;

  automatedTests = call ./automated-tests {};

  generatedSources = call ./generated-sources.nix {};
  generatedDocs = call ./generated-docs {};
  adHocBuildTests = call ./ad-hoc-build-tests {};
  rustAggregate = call ./rust-aggregate {};

  mkEverything =
    { cached ? []
    , extraPure ? []
    , impure ? []
    }:
    let
      mk = name: drvs: pkgs.dev.writeText name (toString (lib.flatten drvs));
    in {
      cached = mk "everything-cached" cached;
      extraPure = mk "everything-pure" extraPure;
      pure = mk "everything-pure" (cached ++ extraPure);
      impure = mk "everything-impure" impure;
      all = mk "everything" (cached ++ extraPure ++ impure);
    };

}
