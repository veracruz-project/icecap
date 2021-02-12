{ icecapPlat
, pkgs_linux
, icecapExtraConfig
, runCommandCC
}:

self: with self;

{
  inherit icecapExtraConfig;

  mkInstance = callPackage ./mk-instance.nix {};
  mkIceDL = callPackage ./mk-icedl.nix {};

  mkRun = callPackage (./run + "/${icecapPlat}") {};

  strip = elf: runCommandCC "stripped.elf" {} ''
    $STRIP -s ${elf} -o $out
  '';

  splitDebug = elf: {
    full = elf;
    min = strip elf;
  };

  trivialSplit = elf: {
    full = elf;
    min = elf;
  };

}
