self: super: with self; {

  overrideConfiguredScope = callPackage ./configured {};

  deviceTree = callPackage ./device-tree.nix {};

  icecap-host = callPackage ./icecap-host.nix {};

  hypervisor-fdt-append-devices = mkTool globalCrates.hypervisor-fdt-append-devices;
  hypervisor-serialize-component-config = mkTool globalCrates.hypervisor-serialize-component-config;
  hypervisor-serialize-event-server-out-index = mkTool globalCrates.hypervisor-serialize-event-server-out-index;

  firecracker = callPackage ./firecracker/firecracker.nix {};
  firecracker-prebuilt = callPackage ./firecracker/firecracker-prebuilt.nix {};
  firectl = callPackage ./firecracker/firectl.nix {};
  libfdt = callPackage ./firecracker/libfdt {};

  # HACK
  linuxKernel = super.linuxKernel // {
    realm.minimal = linuxKernel.guest.minimal;
  };

}
