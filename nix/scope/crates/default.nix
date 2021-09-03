{ lib, hostPlatform, callPackage, newScope
, icecapSrcAbsSplit, icecapSrcRelRaw, mkIceCapSrc
, crateUtils
}:

with lib;

{ seL4 ? false, debug ? false, benchmark ? false, extraArgs ? {} }:

let

  localCrates = mapAttrs (name: path:
    let crate = callCrate path; in assert head (splitString "_" name) == crate.name; crate
   ) (import (icecapSrcRelRaw "rust/crates.nix") {
     inherit lib seL4 debug benchmark;
   });

  callCrate = path:
    let
      mkBase = ext: args: crateUtils.mkGeneric ({
        src = icecapSrcAbsSplit (path + "/src");
      } // ext // args);
    in newScope ({
      inherit localCrates patches;

      inherit lib seL4 debug benchmark;

      mk = mkBase {};
      mkBin = mkBase { isBin = true; };

      # abbreviations
      serdeMin = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };

    } // extraArgs) (path + "/cargo.nix") {};

  patches = import ./patches.nix {
    inherit mkIceCapSrc;
  };

in localCrates // {
  _localCrates = localCrates;
  _patches = patches;
}
