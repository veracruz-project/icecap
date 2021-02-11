# TODO camlCase

{ lib, runCommand, linkFarm, emptyFile
, nixToToml
}:

with lib;

rec {

  clobber = fold recursiveUpdate {};

  mkGeneric =
    { name, src
    , isBin ? false, isStaticlib ? false
    , deps ? [], depsPhantom ? []
    , propagate ? {}
    , buildScript ? null
    , ...
    } @ args:
    let
      mk = src': nixToToml (clobber [

        {
          package = {
            inherit name;
            version = "0.1.0";
            edition = "2018";
          };
          dependencies = listToAttrs (map (crate: nameValuePair crate.name {
            path = "../${crate.name}";
          }) deps);
        }

        (if isBin then {
          bin = [
            { inherit name; path = "${src'}/main.rs"; }
          ];
        } else {
          lib = {
            path = "${src'}/lib.rs";
          } // optionalAttrs isStaticlib {
            crate-type = [ "staticlib" ];
            name = "${kebabToCaml name}_rs";
          };
        })

        (removeAttrs args [
          "name" "src" "srcLocal"
          "isBin" "isStaticlib"
          "deps" "depsPhantom"
          "propagate" "buildScript"
        ])

        (optionalAttrs (buildScript != null) {
          package.build = emptyFile;
          package.links = "dummy-link-${name}";
        })

      ]);

    in {
      type = "path";
      inherit name;
      src = mkLink (mk src.store);
      srcLocal = mkLink (mk src.env);
      srcDummy = mkLink (mk dummySrc);
      deps = deps ++ depsPhantom;
      inherit propagate buildScript;
    };

  mkFromToml = { name, src, srcDummy ? null, depsPhantom ? [] }: {
    type = "path";
    inherit name srcDummy;
    src = src.store;
    srcLocal = src.env;
    deps = depsPhantom;
    buildScript = null;
  };

  dummySrc = lib.fix (self: runCommand "src" {
    passthru.lib = "${self.outPath}/lib.rs";
  } ''
    mkdir $out
    touch $out/lib.rs
  '');

  mkLink = manifest: linkFarm "crate" [
    { name = "Cargo.toml"; path = manifest; }
  ];

  flatDeps =
    let
      attrsOf = crates: listToAttrs (map pairOf crates);
      pairOf = crate: nameValuePair crate.name crate;
      go = seen: queue:
        let
          queueNames = attrNames queue;
        in
          if length queueNames == 0
          then seen
          else
            let
              queue' = attrsOf (attrVals (tail queueNames) queue);
              ext = attrsOf queue.${head queueNames}.deps;
            in
              go (seen // ext) (queue' // ext);
    in root: go {} (attrsOf [ root ]);

  flatDepsWithRoot = rootCrate: flatDeps rootCrate // {
    ${rootCrate.name} = rootCrate;
  };

  collect = crates: linkFarm "crates" (map (crate: {
    name = crate.name;
    path = crate.src;
  }) crates);

  collectLocal = crates: linkFarm "crates" (map (crate: {
    name = crate.name;
    path = crate.srcLocal;
  }) crates);

  collectDummies = crates: dummies: linkFarm "crates" (map (crate: {
    name = crate.name;
    path = crate.src;
  }) crates ++ map (crate: {
    name = crate.name;
    path = crate.srcDummy;
  }) dummies);

  kebabToCaml = lib.replaceStrings [ "-" ] [ "_" ];
}
