{ icecapPlat
, pkgs_linux
, icecapExtraConfig
}:

self: with self;

{
  inherit icecapExtraConfig;

  mkInstance = callPackage ./mk-instance.nix {};
  mkIceDL = callPackage ./mk-icedl.nix {};

  mkRun = callPackage (./run + "/${icecapPlat}") {};

  trivialSplit = elf: {
    min = elf;
    full = elf;
  };
}
