self: with self;

let
  inherit (framework) lib;

in {

  examples = import ../../examples {
    inherit framework hypervisor;
  };
  demos = {
    hypervisor-demo = import ../../demos/hypervisor-demo {
      inherit hypervisor;
    };
  };

  everything =
    let
      combine = attr: [
        framework.everything.${attr}
        hypervisor.everything.${attr}
      ];
      mk = name: drvs: framework.pkgs.dev.writeText name (toString (lib.flatten drvs));
    in rec {
      cached = mk "everything-cached" [
        (combine "cached")
        (lib.mapAttrsToList (_: lib.mapAttrsToList (_: plat: plat.run)) demos)
        (lib.mapAttrsToList (_: example: example.run) examples)
      ];
      pure = mk "everything-pure" [
        cached
        (combine "pure")
      ];
      impure = mk "everything-impure" [
        (combine "impure")
      ];
      all = mk "everything-all" [
        pure
        impure
      ];
    };

}
