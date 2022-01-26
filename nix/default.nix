rec {
  framework = import ./framework;

  hypervisor = import ./hypervisor {
    inherit framework;
  };

  examples = import ../examples {
    inherit framework hypervisor;
  };

  demos = {
    hypervisor-demo = import ../demos/hypervisor-demo {
      inherit hypervisor;
    };
  };

  everything =
    let
      inherit (framework) lib;
      mk = name: drvs: framework.pkgs.dev.writeText name (toString (lib.flatten drvs));
    in rec {
      cached = mk "everything-cached" [
        framework.everything.cached
        hypervisor.everything.cached
        (lib.mapAttrsToList (_: lib.mapAttrsToList (_: plat: plat.run)) demos)
        (lib.mapAttrsToList (_: example: example.run) examples)
      ];
      pure = mk "everything-pure" [
        cached
        framework.everything.pure
        hypervisor.everything.pure
      ];
      impure = mk "everything-impure" [
        framework.everything.impure
      ];
      all = mk "everything-all" [
        pure
        impure
      ];
    };

}
