let
  framework = import ./framework;
  hypervisor = import ./hypervisor { inherit framework; };
in rec {
  inherit framework hypervisor;
  meta = import ./meta {
    inherit framework hypervisor;
  };

  inherit (hypervisor.framework) lib pkgs;
}
