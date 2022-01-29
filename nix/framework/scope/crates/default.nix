{ lib, newScope, writeText
, icecapSrc, icecapExternalSrc
, crateUtils
}:

let

  localCrates = lib.mapAttrs (name: path:
    let crate = callCrate path {};
    in lib.traceIf (name != crate.name) crate.name (assert name == crate.name; crate)
   ) (import (icecapSrc.relativeRaw "rust/crates.nix"));

  callCrate = path:

    let
      mkBase = preArgs: args:
        let
          passthru = args.nix.passthru or {};
        in
          crateUtils.mkCrate (crateUtils.clobber [
            {
              nix.srcPath = path + "/src";
              nix.buildScript =
                if (passthru.buildScriptPath or null) != null
                then icecapSrc.absoluteSplit (path + "/${passthru.buildScriptPath}")
                else null;
              nix.extraLinks = lib.flip lib.mapAttrs (icecapSrc.splitTrivially null) (k: _v: lib.forEach (passthru.extraPaths or []) (name: {
                inherit name;
                path = (icecapSrc.absoluteSplit (path + "/${name}")).${k};
              }));
              nix.passthru.path = path;
            }
            {
              # defaults
              nix.passthru.requiresSeL4 = false;
              nix.passthru.requiresLinux = false;
              nix.passthru.excludeFromDocs = false;
              nix.passthru.excludeFromBuild = false;
            }
            preArgs
            args
          ]);

    in newScope {

      inherit localCrates;

      mk = mkBase {};
      mkBin = mkBase { nix.isBin = true; };
      mkSeL4 = mkBase { nix.passthru.requiresSeL4 = true; };
      mkLinux = mkBase { nix.passthru.requiresLinux = true; };
      mkSeL4Bin = mkBase { nix.isBin = true; nix.passthru.requiresSeL4 = true; };
      mkLinuxBin = mkBase { nix.isBin = true; nix.passthru.requiresLinux = true; };

      inherit patches;

      # convenient abbreviation
      serdeMin = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };
      postcardCommon = { version = "*"; default-features = false; features = [ "alloc" ]; };

    } (path + "/crate.nix");

  # HACK
  patches = icecapExternalSrc.crates.git;

  cratesForSeL4 = lib.filterAttrs (_: crate: !crate.hack.elaboratedNix.passthru.requiresLinux && !crate.hack.elaboratedNix.passthru.excludeFromBuild) localCrates;
  cratesForLinux = lib.filterAttrs (_: crate: !crate.hack.elaboratedNix.passthru.requiresSeL4 && !crate.hack.elaboratedNix.passthru.excludeFromBuild) localCrates;
  cratesForDocs = lib.filterAttrs (_: crate: !crate.hack.elaboratedNix.passthru.excludeFromDocs && !crate.hack.elaboratedNix.passthru.excludeFromBuild) localCrates;

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
