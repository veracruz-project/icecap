with import ../..;

let
  roots = [
    # HACK
    instances.virt.demos.realm-vm.run
    instances.rpi4.demos.realm-vm.run
    instances.virt.test.realm-vm.run
    instances.rpi4.test.realm-vm.run
    instances.rpi4.test.firecracker.boot
  ];

in
pkgs.dev.writeText "root" (toString roots)
