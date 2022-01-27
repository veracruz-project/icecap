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
    , excess ? []
    }:
    let
      mk = suffix: drvs: pkgs.dev.writeText "everything${suffix}" (toString (lib.flatten drvs));

      pure = cached ++ extraPure;
      all = pure ++ impure;
      allWithExcess = all ++ excess;
    in {
      cached = mk "-cached" cached;
      extraPure = mk "-extra-pure" extraPure;
      excess = mk "-excess" excess;
      impure = mk "-impure" impure;

      pure = mk "-pure" pure;
      all = mk "" all;
      allWithExcess = mk "-with-excess" allWithExcess;
    };

}
