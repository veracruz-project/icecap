let
  framework = import ./framework;
  hypervisor = import ./hypervisor { inherit framework; };
in framework.lib.fix (self: {
  inherit framework hypervisor;
  inherit (hypervisor.framework) lib pkgs;
} // import ./top-level self)
