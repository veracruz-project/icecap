{ }:

self: super: with self;

{

  icecapFirmware = callPackage ./firmware.nix {};

  hypervisorComponents = callPackage ./hypervisor-components.nix {};

  mkHypervisorIceDL = callPackage ./capdl/mk-hypervisor-icedl.nix {};
  mkRealm = callPackage ./capdl/mk-realm.nix {};
  mkLinuxRealm = callPackage ./capdl/mk-linux-realm.nix {};
  mkMirageRealm = callPackage ./capdl/mk-mirage-realm.nix {};

}
