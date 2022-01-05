let
  icecap = import ../.;

  inherit (icecap) lib pkgs;

  examples = {
    minimal-root = ./01-minimal-root;
    minimal-root-with-rust = ./02-minimal-root-with-rust;
    minimal-capdl = ./03-minimal-capdl;
    minimal-capdl-with-rust = ./04-minimal-capdl-with-rust;
    basic-system = ./05-basic-system;
    hypervisor = ./06-hypervisor;
  };

in lib.flip lib.mapAttrs examples (_: path:
  import path { inherit lib pkgs; }
)
