let
  inherit (framework) lib;

  framework = import ./framework;

  hypervisor = import ./hypervisor {
    inherit framework;
  };

  applied = {
    framework = lib.mapAttrsRecursive (_: f: f { inherit framework; }) unapplied.framework;
    hypervisor = lib.mapAttrsRecursive (_: f: f { inherit hypervisor; }) unapplied.hypervisor;
  };

  appliedStandAlone = lib.mapAttrsRecursive (_: f: f {}) unapplied;

  unapplied = lib.mapAttrsRecursive (_: import) {
    framework = {
      examples = {
        minimal-root-task = ../examples/01-minimal-root-task;
        minimal-root-task-with-rust = ../examples/02-minimal-root-task-with-rust;
        minimal-capdl = ../examples/03-minimal-capdl;
        minimal-capdl-with-rust = ../examples/04-minimal-capdl-with-rust;
        basic-system = ../examples/05-basic-system;
        dynamism = ../examples/06-dynamism;
      };
      demos = {
      };
    };
    hypervisor = {
      examples = {
        hypervisor = ../examples/07-hypervisor;
      };
      demos = {
        hypervisor-demo = ../demos/hypervisor-demo;
      };
    };
  };

in rec {
  inherit framework hypervisor;

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

  examples = applied.framework.examples // applied.hypervisor.examples;
  demos = applied.framework.demos // applied.hypervisor.demos;

  testStandAlone = framework.pkgs.dev.writeText "test-stand-alone"
    (toString (map (example: example.run) (lib.collect (example: example ? run) appliedStandAlone)));

}
