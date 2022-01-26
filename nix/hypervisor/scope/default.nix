self: super: with self; {

  overrideConfiguredScope = callPackage ./configured {};

  deviceTree = callPackage ./device-tree {};

  linuxKernel = super.linuxKernel // {
    realm = linuxKernel.guest;
  };

  icecap-host = callPackage ./linux-user/icecap-host.nix {};

  firecracker = callPackage ./linux-user/firecracker/firecracker.nix {};
  firecracker-prebuilt = callPackage ./linux-user/firecracker/firecracker-prebuilt.nix {};
  firectl = callPackage ./linux-user/firecracker/firectl.nix {};
  libfdt = callPackage ./linux-user/firecracker/libfdt {};

  icecap-append-devices = mkTool globalCrates.icecap-append-devices;
  icecap-serialize-builtin-config = mkTool globalCrates.icecap-serialize-builtin-config;
  icecap-serialize-event-server-out-index = mkTool globalCrates.icecap-serialize-event-server-out-index;

}
