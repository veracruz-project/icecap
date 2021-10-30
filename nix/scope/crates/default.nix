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
      mkBase = isBin: args: crateUtils.mkCrate (lib.recursiveUpdate args {
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
      });

    in newScope {

      inherit localCrates;

      mk = mkBase false;
      mkBin = mkBase true;

      # convenient abbreviation
      serdeMin = { version = "*"; default-features = false; features = [ "alloc" "derive" ]; };

    } (path + "/crate.nix");

  patches = import ./patches.nix {
    inherit icecapSrc;
  };

in localCrates // {
  _localCrates = localCrates;
  _patches = patches;
}
