{ lib, newScope, writeText
, icecapSrc, icecapExternalSrc
, crateUtils
}:

let

  localCrates = lib.mapAttrs (name: path:
    let crate = callCrate path {};
    in assert name == crate.name; crate
   ) (import (icecapSrc.relativeRaw "rust/crates.nix"));

  callCrate = path:

    let
      mkBase = isBin: isSeL4: exclude: args: crateUtils.mkCrate (crateUtils.clobber [
        args
        {
          nix.srcPath = icecapSrc.absolute (path + "/src");
          nix.isBin = isBin;
          nix.buildScriptHack =
            if args.nix.buildScriptHack or false
            then icecapSrc.absoluteSplit (path + "/build.rs")
            else null;
          nix.keepFilesHack = lib.forEach (args.nix.keepFilesHack or []) (name: {
            inherit name;
            path = icecapSrc.absolute (path + "/${name}");
          });
          nix.passthru.path = path; # HACK
          nix.passthru.isSeL4 = isSeL4;
          nix.passthru.exclude = exclude;
        }
        (lib.optionalAttrs (!((args.nix ? passthru) && (args.nix.passthru ? noDoc))) {
          nix.passthru.noDoc = false;
        })
      ]);

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
      postcardCommon = { version = "*"; default-features = false; features = [ "alloc" ]; };

    } (path + "/crate.nix");

  # HACK
  patches = icecapExternalSrc.crates.git;

  cratesForSeL4 = lib.filterAttrs (_: crate: crate.hack.elaboratedNix.passthru.isSeL4 && !crate.hack.elaboratedNix.passthru.exclude) localCrates;
  cratesForLinux = lib.filterAttrs (_: crate: !crate.hack.elaboratedNix.passthru.isSeL4 && !crate.hack.elaboratedNix.passthru.exclude) localCrates;
  cratesForDocs = lib.filterAttrs (_: crate: !crate.hack.elaboratedNix.passthru.noDoc && !crate.hack.elaboratedNix.passthru.exclude) localCrates;

  mkCratesForTxt = attrs: writeText "crates.txt" (lib.concatStrings (lib.sort (x: y: x < y) (lib.mapAttrsToList (k: _: "${k}\n") attrs)));

in localCrates // rec {
  _localCrates = localCrates;
  _patches = patches;
  _cratesFor = {
    seL4 = cratesForSeL4;
    linux = cratesForLinux;
    docs = cratesForDocs;
  };
  _cratesForTxt = lib.mapAttrs (lib.const mkCratesForTxt) _cratesFor;
}
