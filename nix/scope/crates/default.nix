{ lib, newScope
, icecapSrc
, crateUtils
}:

let

  localCrates = lib.mapAttrs (name: path:
    let crate = callCrate path {};
    in assert name == crate.name; crate
   ) (import (icecapSrc.relativeRaw "rust/crates.nix"));

  callCrate = path:

    let
      mkBase = isBin: isSeL4: exclude: args: crateUtils.mkCrate (lib.recursiveUpdate args {
        nix.src = icecapSrc.absoluteSplit (path + "/src");
        nix.isBin = isBin;
        nix.buildScriptHack =
          if args.nix.buildScriptHack or false
          then icecapSrc.absoluteSplit (path + "/build.rs")
          else null;
        nix.keepFilesHack = lib.forEach (args.nix.keepFilesHack or []) (name: {
          inherit name;
          path = icecapSrc.absolute (path + "/${name}");
        });
        nix.hack.path = path; # HACK
        nix.hack.isSeL4 = isSeL4;
        nix.hack.exclude = exclude;
      });

    in newScope {

      inherit localCrates;

      mk = mkBase false false false;
      mkBin = mkBase true false false;
      mkSeL4 = mkBase false true false;
      mkComponent = mkBase true true false;
      mkExclude = mkBase false false true;
      mkExcludeBin = mkBase true false true;

      inherit patches;

      # convenient abbreviation
      serdeMin = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };

    } (path + "/crate.nix");

  patches = import ./patches.nix {
    inherit icecapSrc;
  };

  icecapBins = lib.filterAttrs (_: crate: crate.hack.elaboratedNix.hack.isSeL4 && !crate.hack.elaboratedNix.hack.exclude) localCrates;
  icecapBinsInv = lib.filterAttrs (_: crate: !crate.hack.elaboratedNix.hack.isSeL4 && !crate.hack.elaboratedNix.hack.exclude)localCrates;

in localCrates // rec {
  _localCrates = localCrates;
  _patches = patches;
  _icecapBins = icecapBins;
  _icecapBinsInv = icecapBinsInv;
}
