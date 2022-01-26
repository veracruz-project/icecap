let
  framework = import ./framework;
  hypervisor = import ./hypervisor { inherit framework; };
in framework.lib.fix (self: {
  inherit framework hypervisor;
} // import ./top-level self)
