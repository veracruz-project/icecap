{ icecapPlat
, linuxPkgs
, icecapExtraConfig
, runCommandCC
}:

self: with self;

{
  inherit icecapExtraConfig;

  mkInstance = callPackage ./mk-instance.nix {};

  mkRun = callPackage ./mk-run.nix {};

}
