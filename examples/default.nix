let
  icecap = import ../.;

  inherit (icecap) lib pkgs;

  examples = {
    minimal-root-task = ./01-minimal-root-task;
    minimal-root-task-with-rust = ./02-minimal-root-task-with-rust;
    minimal-capdl = ./03-minimal-capdl;
    minimal-capdl-with-rust = ./04-minimal-capdl-with-rust;
    basic-system = ./05-basic-system;
    hypervisor = ./06-hypervisor;
  };

in lib.flip lib.mapAttrs examples (_: path:
  import path { inherit lib pkgs; }
)
