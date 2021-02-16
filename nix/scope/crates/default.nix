{ lib
, nixToToml
, icecapSrcRelSplit
, hostPlatform
, runCommand, linkFarm
, callPackage
, crateUtils
, mkIceCapSrc
}:

with lib;

let

  flatten = attrs:
    listToAttrs
      (concatMap
        (mapAttrsToList (name: value: { inherit name value; }))
        (attrValues attrs));

  manifests = fix (self: flatten
    (mapAttrs (dir: mapAttrs (name: f: f name dir)) (
      callPackage ./manifests.nix {} {
        inherit lib crateUtils;
        inherit mk mkBin mkLib;
        inherit patches;
      } self
    ))
  );

  mkBase = ext: args: name: dir: crateUtils.mkGeneric (args // rec {
    inherit name;
    src = icecapSrcRelSplit "rust/${dir}/${name}";
  } // ext);

  mk = mkBase {};

  mkLib = mkBase {
    isStaticlib = true;
  };

  mkBin = mkBase {
    isBin = true;
  };

  patches = import ./patches.nix {
    inherit mkIceCapSrc;
  };

in manifests // {
  _patches = patches;
}
