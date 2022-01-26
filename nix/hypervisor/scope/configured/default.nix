{ makeOverridable' }:

self: super: with self;

{

  icecapFirmware = callPackage ./firmware.nix {};

  hypervisorComponents = callPackage ./hypervisor-components.nix {};

  mkRealm = callPackage ./capdl/mk-realm.nix {};
  mkLinuxRealm = callPackage ./capdl/mk-linux-realm.nix {};
  mkMirageRealm = callPackage ./capdl/mk-mirage-realm.nix {};

}
