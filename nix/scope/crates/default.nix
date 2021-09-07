{ lib, newScope
, icecapSrc
, crateUtils
}:

{ seL4 ? false, debug ? false, benchmark ? false, extraArgs ? {} }:

let

  localCrates = lib.mapAttrs (name: path:
    let crate = callCrate path {};
    in assert name == crate.name; crate
   ) (import (icecapSrc.relativeRaw "rust/crates.nix") {
     inherit lib seL4 debug benchmark;
   });

  callCrate = path:

    let
      mkBase = isBin: args: crateUtils.mkCrate (lib.recursiveUpdate {
        nix.src = icecapSrc.absoluteSplit (path + "/src");
        nix.isBin = isBin;
      } args);

    in newScope ({

      inherit lib seL4 debug benchmark;
      inherit localCrates patches;

      mk = mkBase false;
      mkBin = mkBase true;

      # convenient abbreviation
      serdeMin = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };

    } // extraArgs) (path + "/cargo.nix");

  patches = import ./patches.nix {
    inherit icecapSrc;
  };

in localCrates // {
  _localCrates = localCrates;
  _patches = patches;
}
