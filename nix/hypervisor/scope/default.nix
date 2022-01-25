self: super: with self; {

  deviceTree = callPackage ./device-tree {};

  linuxKernel = super.linuxKernel // {
    realm = linuxKernel.guest;
  };

  icecap-host = callPackage ./linux-user/icecap-host.nix {};

  firecracker = callPackage ./linux-user/firecracker/firecracker.nix {};
  firecracker-prebuilt = callPackage ./linux-user/firecracker/firecracker-prebuilt.nix {};
  firectl = callPackage ./linux-user/firecracker/firectl.nix {};
  libfdt = callPackage ./linux-user/firecracker/libfdt {};

}
