with import ../..;

let
  roots = [
    # HACK
    instances.virt.demos.realm-vm.run
    instances.rpi4.demos.realm-vm.run
  ];

in
pkgs.dev.writeText "root" (toString roots)
