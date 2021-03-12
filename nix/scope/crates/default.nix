{ lib, hostPlatform, callPackage, newScope
, icecapSrcAbsSplit, icecapSrcRelRaw, mkIceCapSrc
, crateUtils
}:

with lib;

let

  localCrates = mapAttrs (name: path:
    let crate = callCrate path; in assert head (splitString "_" name) == crate.name; crate
   ) (import (icecapSrcRelRaw "rust/crates.nix"));

  callCrate = path:
    let
      mkBase = ext: args: crateUtils.mkGeneric ({
        src = icecapSrcAbsSplit (path + "/src");
      } // ext // args);
    in newScope {
      inherit localCrates patches hostPlatform;
      mk = mkBase {};
      mkBin = mkBase { isBin = true; };

      # abbreviations
      serdeMin = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };

    } (path + "/cargo.nix") {};

  patches = import ./patches.nix {
    inherit mkIceCapSrc;
  };

in localCrates // {
  _localCrates = localCrates;
  _patches = patches;
}
