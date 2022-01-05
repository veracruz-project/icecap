let
  icecap = import ../.;

  inherit (icecap) lib pkgs;

  demos = {
    hypervisor-demo = ./hypervisor-demo;
  };

in lib.flip lib.mapAttrs demos (_: path:
  import path { inherit lib pkgs; }
)
