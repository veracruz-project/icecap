{ lib, stdenv, buildPackages, buildPlatform, hostPlatform
, writeText, linkFarm, emptyFile
, nixToToml
, rustTargets, rustTargetName
, icecapSrc
}:

with lib;

rec {

  clobber = fold recursiveUpdate {};

  mkCrate =
    let
      elaborateNix =
        { name
        , srcPath ? null, src ? icecapSrc.absoluteSplitWithName name srcPath
        , buildScript ? null
        , extraLinks ? icecapSrc.splitTrivially []
        , isBin ? false
        , local ? {}
        , passthru ? {}
        }:
        {
          inherit
            name src buildScript extraLinks isBin
            local
            passthru;
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

        mk = src: buildScript:
          nixToToml (clobber [
            {
              package = {
                inherit (elaboratedNix) name;
                version = "0.1.0";
                edition = "2018";
              } // optionalAttrs (buildScript != null) {
                build = buildScript;
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

      in lib.fix (self: {
        inherit (elaboratedNix) name;
        store = mkLink elaboratedNix.extraLinks.store (mk elaboratedNix.src.store (elaboratedNix.buildScript.store or null));
        env = mkLink elaboratedNix.extraLinks.env (mk elaboratedNix.src.env (elaboratedNix.buildScript.env or null));
        dummy = mkLink elaboratedNix.extraLinks.store (mk (if elaboratedNix.isBin then dummySrcBin else dummySrcLib) dummyBuildScript);
        localDependencies = flatten elaboratedNix.local;

        closure = {
          "${self.name}" = self;
        } // lib.foldl' (acc: crate: acc // crate.closure) {} self.localDependencies;

        # HACK
        hack = {
          inherit elaboratedNix rest;
        };
      });

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
      path = dummyMain name;
    })
  ];

  dummyBuildScript = dummyMain "build.rs";

  dummyMain = name: writeText name ''
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

  mkLink = extra: manifest: linkFarm "crate" ([
    { name = "Cargo.toml"; path = manifest; }
  ] ++ extra);

  closure = root: root.closure;
  closureMany = lib.foldl' (acc: crate: acc // closure crate) {};

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

  baseEnv = ccEnv // {
    RUST_TARGET_PATH = rustTargets;
  };

  linkerCargoConfig = {
    target = {
      ${rustTargetName}.linker =
        if hostPlatform.isNone || hostPlatform.isMusl /* HACK for proper static linking on musl */
        then "${stdenv.cc.targetPrefix}ld"
        else "${stdenv.cc.targetPrefix}cc";
    };
  };

  denyWarningsCargoConfig = {
    target."cfg(all())".rustflags = ["-D" "warnings"];
  };

  baseCargoConfig = clobber [
    linkerCargoConfig
    # denyWarningsCargoConfig
  ];

}
