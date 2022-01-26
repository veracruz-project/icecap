{ makeOverridable' }:

self: super: with self;

{

  icecapFirmware = makeOverridable' compose {};

  hypervisorComponents = callPackage ./sel4-user/rust/hypervisor-components.nix {};

  mkRealm = callPackage ./capdl/mk-realm.nix {};
  mkLinuxRealm = callPackage ./capdl/mk-linux-realm.nix {};
  mkMirageRealm = callPackage ./capdl/mk-mirage-realm.nix {};

}
