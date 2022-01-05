let
  icecap = import ../.;

  inherit (icecap) lib pkgs;

  demos = {
    hypervisor = ./hypervisor;
  };

in lib.flip lib.mapAttrs demos (_: path:
  import path { inherit lib pkgs; }
)
