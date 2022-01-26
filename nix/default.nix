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
      inherit (framework) lib mkEverything;
    in mkEverything {
      cached = [
        framework.everything.cached
        hypervisor.everything.cached
        (lib.mapAttrsToList (_: lib.mapAttrsToList (_: plat: plat.run)) demos)
        (lib.mapAttrsToList (_: example: example.run) examples)
      ];
      extraPure = [
        framework.everything.extraPure
        hypervisor.everything.extraPure
      ];
      impure = [
        framework.everything.impure
      ];
    };

}
