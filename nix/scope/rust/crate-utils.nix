{ lib, stdenv, buildPackages, buildPlatform, hostPlatform
, writeText, linkFarm, emptyFile
, nixToToml
, rustTargets, rustTargetName
}:

with lib;

rec {

  clobber = fold recursiveUpdate {};

  mkCrate =
    let
      elaborateNix = 
        { name, src
        , buildScriptHack ? null
        , keepFilesHack ? []
        , isBin ? false
        , local ? {}
        , propagate ? {}
        , hack ? {}, # HACK
        }:
        {
          inherit
            name src buildScriptHack keepFilesHack isBin
            local
            propagate
            hack; # HACK
        };

    in
      { nix ? {}, ... } @ args:

      let
        elaboratedNix = elaborateNix nix;

        paths = lib.flip lib.mapAttrsRecursive elaboratedNix.local (_: v:
          if !lib.isList v then v else lib.listToAttrs (map (otherCrate: lib.nameValuePair otherCrate.name {
            path = "../${otherCrate.name}";
          }) v)
        );

        rest = removeAttrs args [ "nix" ];

        flatten = x: if lib.isList x then x else lib.concatMap flatten (lib.attrValues x);

        mk = src: buildRs:
          nixToToml (clobber [
            {
              package = {
                inherit (elaboratedNix) name;
                version = "0.1.0";
                edition = "2018";
              } // optionalAttrs (elaboratedNix.buildScriptHack != null) {
                build = buildRs;
              };
            }

            (if elaboratedNix.isBin then {
              bin = [
                { inherit (elaboratedNix) name;
                  path = "${src}/main.rs";
                }
              ];
            } else {
              lib = {
                path = "${src}/lib.rs";
              };
            })

            paths
            rest
          ]);

      in {
        inherit (elaboratedNix) name propagate;
        store = mkLink elaboratedNix.keepFilesHack (mk elaboratedNix.src.store elaboratedNix.buildScriptHack.store);
        env = mkLink elaboratedNix.keepFilesHack (mk elaboratedNix.src.env elaboratedNix.buildScriptHack.store);
        dummy = mkLink elaboratedNix.keepFilesHack (mk (if elaboratedNix.isBin then dummySrcBin else dummySrcLib) "${dummySrcBin}/main.rs");
        localDependencies = flatten elaboratedNix.local;
        # HACK
        hack = {
          inherit elaboratedNix rest;
        };
      };

  dummySrcLib = linkFarm "dummy-src" [
    (rec {
      name = "lib.rs";
      path = writeText name ''
        #![no_std]
      '';
    })
  ];

  dummySrcBin = linkFarm "dummy-src" [
    (rec {
      name = "main.rs";
      path = writeText name ''
        #![cfg_attr(target_os = "icecap", no_std)]
        #![cfg_attr(target_os = "icecap", no_main)]
        #![cfg_attr(target_os = "icecap", feature(lang_items))]

        #[cfg(target_os = "icecap")]
        #[panic_handler]
        extern fn panic_handler(_: &core::panic::PanicInfo) -> ! {
          todo!()
        }

        #[cfg(target_os = "icecap")]
        #[lang = "eh_personality"]
        extern fn eh_personality() {
        }

        #[cfg(not(target_os = "icecap"))]
        fn main() {
        }
      '';
    })
  ];

  mkLink = extra: manifest: linkFarm "crate" ([
    { name = "Cargo.toml"; path = manifest; }
  ] ++ extra);

  closure = root: closure' [ root ];

  closure' =
    let
      nameOf = crate: crate.name;
      dependenciesOf = crate: crate.localDependencies;

      toAttrs = crates: listToAttrs (map (crate: nameValuePair (nameOf crate) crate) crates);

      go = seen: queue:
        if queue == {}
        then seen
        else
          let
            queueNames = attrNames queue;
            current = queue.${head queueNames};
            currentDependencies = dependenciesOf queue.${head queueNames};
            queue' = toAttrs (attrVals (tail queueNames) queue);
            seenExtension = toAttrs ([ current ] ++ currentDependencies);
            queueExtension = toAttrs currentDependencies;
          in
            go (seen // seenExtension) (queue' // queueExtension);

    in roots: go {} (toAttrs roots);

  collectStore = crates: linkFarm "crates" (map (crate: {
    name = crate.name;
    path = crate.store;
  }) crates);

  collectEnv = crates: linkFarm "crates" (map (crate: {
    name = crate.name;
    path = crate.env;
  }) crates);

  collectDummies = crates: dummies: linkFarm "crates" (map (crate: {
    name = crate.name;
    path = crate.store;
  }) crates ++ map (crate: {
    name = crate.name;
    path = crate.dummy;
  }) dummies);

  ccEnv = {
    "CC_${buildPlatform.config}" = "${buildPackages.stdenv.cc.targetPrefix}cc";
    "CXX_${buildPlatform.config}" = "${buildPackages.stdenv.cc.targetPrefix}c++";
  } // {
    "CC_${rustTargetName}" = "${stdenv.cc.targetPrefix}cc";
    "CXX_${rustTargetName}" = "${stdenv.cc.targetPrefix}c++";
  };

  linkerCargoConfig = {
    target = {
      ${rustTargetName}.linker =
        if hostPlatform.isNone || hostPlatform.isMusl /* HACK for proper static linking on musl */
        then "${stdenv.cc.targetPrefix}ld"
        else "${stdenv.cc.targetPrefix}cc";
    };
  };

  baseEnv = ccEnv // {
    RUST_TARGET_PATH = rustTargets;
  };

  baseCargoConfig = linkerCargoConfig;

}
