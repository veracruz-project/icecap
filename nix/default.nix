let
  inherit (framework) lib;

  framework = import ./framework;

  hypervisor = import ./hypervisor {
    inherit framework;
  };

  examplesAndDemos = lib.mapAttrsRecursive (_: import) {
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

  examplesAndDemosIntegrated = {
    framework = lib.mapAttrsRecursive (_: f: f { inherit framework; }) examplesAndDemos.framework;
    hypervisor = lib.mapAttrsRecursive (_: f: f { inherit hypervisor; }) examplesAndDemos.hypervisor;
  };

  examplesAndDemosStandingAlone = lib.mapAttrsRecursive (_: f: f {}) examplesAndDemos;

  collectRun = attrs: map (x: x.run) (lib.collect (x: x ? run) attrs);

in rec {
  inherit framework hypervisor;

  examples = examplesAndDemosIntegrated.framework.examples // examplesAndDemosIntegrated.hypervisor.examples;
  demos = examplesAndDemosIntegrated.framework.demos // examplesAndDemosIntegrated.hypervisor.demos;

  everything = framework.mkEverything {
    cached = [
      framework.everything.cached
      hypervisor.everything.cached
      (collectRun examplesAndDemosIntegrated)
    ];
    extraPure = [
      framework.everything.extraPure
      hypervisor.everything.extraPure
    ];
    impure = [
      framework.everything.impure
    ];
  };

  testStandingAlone = framework.pkgs.dev.writeText "test-standing-alone"
    (toString (collectRun examplesAndDemosStandingAlone));

}
