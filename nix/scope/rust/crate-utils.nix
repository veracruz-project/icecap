{ lib, stdenv, buildPackages, buildPlatform, hostPlatform
, writeText, linkFarm, emptyFile
, nixToToml
, rustTargets
}:

with lib;

rec {

  clobber = fold recursiveUpdate {};

  mkCrate =
    let
      elaborateNix = 
        { name, src
        , isBin ? false, isStaticlib ? false
        , localDependencies ? [], phantomLocalDependencies ? []
        , localDependencyAttributes ? {} # HACK
        , propagate ? {}
        , buildScript ? null
        }:
        {
          inherit
            name src isBin isStaticlib
            localDependencies phantomLocalDependencies localDependencyAttributes
            propagate buildScript;
        };

    in
      { nix ? {}, ... } @ args:

      let
        elaboratedNix = elaborateNix nix;

        mk = src: nixToToml (clobber [

          {
            package = {
              inherit (elaboratedNix) name;
              version = "0.1.0";
              edition = "2018";
            };
            dependencies = listToAttrs (lib.flip map elaboratedNix.localDependencies (crate: nameValuePair crate.name ({
              path = "../${crate.name}";
            } // (elaboratedNix.localDependencyAttributes.${crate.name} or {}))));
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
            } // optionalAttrs elaboratedNix.isStaticlib {
              crate-type = [ "staticlib" ];
              name = "${kebabToSnake elaboratedNix.name}_rs";
            };
          })

          (optionalAttrs (elaboratedNix.buildScript != null) {
            package.build = emptyFile;
            package.links = "dummy-link-${elaboratedNix.name}";
          })

          (removeAttrs args [ "nix" ])

        ]);

      in {
        inherit (elaboratedNix) name propagate buildScript;
        store = mkLink (mk elaboratedNix.src.store);
        env = mkLink (mk elaboratedNix.src.env);
        dummy = mkLink (mk (if elaboratedNix.isBin then dummySrcBin else dummySrcLib));
        localDependencies = elaboratedNix.localDependencies ++ elaboratedNix.phantomLocalDependencies;
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

  mkLink = manifest: linkFarm "crate" [
    { name = "Cargo.toml"; path = manifest; }
  ];

  closure =
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

    in root: go {} (toAttrs [ root ]);

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

  kebabToSnake = lib.replaceStrings [ "-" ] [ "_" ];

  ccEnv = {
    "CC_${buildPlatform.config}" = "${buildPackages.stdenv.cc.targetPrefix}cc";
    "CXX_${buildPlatform.config}" = "${buildPackages.stdenv.cc.targetPrefix}c++";
  } // {
    "CC_${hostPlatform.config}" = "${stdenv.cc.targetPrefix}cc";
    "CXX_${hostPlatform.config}" = "${stdenv.cc.targetPrefix}c++";
  };

  linkerCargoConfig = {
    target = {
      ${buildPlatform.config}.linker = "${buildPackages.stdenv.cc.targetPrefix}cc";
    } // {
      ${hostPlatform.config}.linker =
        if hostPlatform.system == "aarch64-none"
        then "${stdenv.cc.targetPrefix}ld"
        else "${stdenv.cc.targetPrefix}cc";
    };
  };

  baseEnv = ccEnv // {
    RUST_TARGET_PATH = rustTargets;
  };

  baseCargoConfig = linkerCargoConfig;

}
