# TODO camlCase

{ lib, runCommand, writeText, linkFarm, emptyFile
, nixToToml
, rustTargets
, stdenv, buildPackages, buildPlatform, hostPlatform
, rustc
}:

with lib;

rec {

  clobber = fold recursiveUpdate {};

  mkGeneric =
    { name, src
    , isBin ? false, isStaticlib ? false
    , localDependencies ? [], phantomLocalDependencies ? []
    , localDependencyAttributes ? {} # HACK
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
          dependencies = listToAttrs (map (crate: nameValuePair crate.name ({
            path = "../${crate.name}";
          } // (localDependencyAttributes.${crate.name} or {}))) localDependencies);
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
          "localDependencies" "phantomLocalDependencies" "localDependencyAttributes"
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
      srcDummy = mkLink (mk (if isBin then dummySrcBin else dummySrcLib));
      localDependencies = localDependencies ++ phantomLocalDependencies;
      inherit propagate buildScript;
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
              ext = attrsOf queue.${head queueNames}.localDependencies;
            in
              go (seen // ext) (queue' // ext);
    in roots: go {} (attrsOf roots);

  flatDepsWithRoot = rootCrate: flatDepsWithRoots  [ rootCrate ];

  flatDepsWithRoots = roots: flatDeps roots // lib.listToAttrs (map (root: {
    inherit (root) name;
    value = root;
  }) roots);

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

  baseCargoConfig = linkerCargoConfig // {
    build.rustc = "${rustc.nativeDrv or rustc}/bin/rustc";
  };

}
