{ framework ? import ../nix/framework
, hypervisor ? import ../nix/hypervisor {}
}:

let
  # HACK
  framework = hypervisor.framework;

  inherit (framework) lib pkgs;

  examples = {
    minimal-root-task = ./01-minimal-root-task;
    minimal-root-task-with-rust = ./02-minimal-root-task-with-rust;
    minimal-capdl = ./03-minimal-capdl;
    minimal-capdl-with-rust = ./04-minimal-capdl-with-rust;
    basic-system = ./05-basic-system;
    dynamism = ./06-dynamism;
    hypervisor = ./07-hypervisor;
  };

in lib.flip lib.mapAttrs examples (_: path:
  import path { inherit lib pkgs; }
)
