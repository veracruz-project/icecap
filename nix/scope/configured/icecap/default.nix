{ callPackage, makeOverridable'
}:

rec {

  mkIceDL = callPackage ./mk-icedl.nix {};
  compose = callPackage ./compose.nix {};

  icecapFirmware = makeOverridable' compose {};

}
