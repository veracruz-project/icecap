self: super: with self; {

  overrideConfiguredScope = callPackage ./configured {};

  deviceTree = callPackage ./device-tree.nix {};

  linuxKernel = super.linuxKernel // {
    realm = linuxKernel.guest;
  };

  icecap-host = callPackage ./icecap-host.nix {};

  firecracker = callPackage ./firecracker/firecracker.nix {};
  firecracker-prebuilt = callPackage ./firecracker/firecracker-prebuilt.nix {};
  firectl = callPackage ./firecracker/firectl.nix {};
  libfdt = callPackage ./firecracker/libfdt {};

  icecap-append-devices = mkTool globalCrates.icecap-append-devices;
  icecap-serialize-builtin-config = mkTool globalCrates.icecap-serialize-builtin-config;
  icecap-serialize-event-server-out-index = mkTool globalCrates.icecap-serialize-event-server-out-index;

}
