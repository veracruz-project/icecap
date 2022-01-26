let
  inherit (framework) lib;

  framework = import ./framework;

  hypervisor = import ./hypervisor {
    inherit framework;
  };

  collectRun = attrs: map (x: x.run) (lib.collect (x: x ? run) attrs);

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

  examples = applied.framework.examples // applied.hypervisor.examples;
  demos = applied.framework.demos // applied.hypervisor.demos;

  everything =
    let
      inherit (framework) lib mkEverything;
    in mkEverything {
      cached = [
        framework.everything.cached
        hypervisor.everything.cached
        (collectRun applied)
      ];
      extraPure = [
        framework.everything.extraPure
        hypervisor.everything.extraPure
        testStandAlone
      ];
      impure = [
        framework.everything.impure
      ];
    };

  testStandAlone = framework.pkgs.dev.writeText "test-stand-alone"
    (toString (collectRun appliedStandAlone));

}
