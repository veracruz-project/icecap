{ lib
, crateUtils
, buildRustPackage
, nixToToml
, hostPlatform
, emptyFile
, fetchCrates, fetchCargo
, runCommand
}:

{ rootCrate, lock
, debug ? true
, extraManifest ? {}
, extraManifestLocal ? {}
, extraCargoConfig ? {}
, extraCargoConfigLink ? {}
, extraArgs
}:
let
  extraManifest_ = extraManifest;
  extraManifestLocal_ = extraManifestLocal;
in
let
  allCratesAttrs = crateUtils.flatDepsWithRoot rootCrate;
  allCrates = lib.attrValues allCratesAttrs;
  allPropagate = crateUtils.clobber (map (x: x.propagate or {}) allCrates);

  src = crateUtils.collect allCrates;
  srcLocal = crateUtils.collectLocal allCrates;

  extraManifest = crateUtils.clobber [
    (allPropagate.extraManifest or {})
    extraManifest_
  ];

  extraManifestLocal = crateUtils.clobber [
    (allPropagate.extrManifestLocal or {})
    extraManifestLocal_
  ];

  workspace = nixToToml (crateUtils.clobber [
    {
      workspace.members = [ "src/${rootCrate.name}" ];
      workspace.exclude = [ "src/*" ];
    }
    extraManifest
  ]);

  workspaceLocal = nixToToml (crateUtils.clobber [
    {
      workspace.members = [ "src/${rootCrate.name}" ];
      workspace.exclude = [ "src/*" ];
    }
    extraManifest
    extraManifestLocal
  ]);

  allExtraCargoConfig = crateUtils.clobber [
    (allPropagate.extraCargoConfig or {})
    extraCargoConfig
    {
      target.${hostPlatform.config} = crateUtils.clobber (map (crate:
      if crate.buildScript == null then {} else {
        ${"dummy-link-${crate.name}"} = crate.buildScript;
      }) allCrates);
    }
    extraCargoConfigLink
  ];

  topSrc = runCommand "x" {} ''
    mkdir -p $out
    ln -s ${src} $out/src
    ln -s ${workspace} $out/Cargo.toml
    ln -s ${lock.store} $out/Cargo.lock
  '';

  build = buildRustPackage ({
    inherit (rootCrate) name;
    extraCargoConfig = allExtraCargoConfig;

    src = topSrc;
    cargoVendorConfig = fetchCrates lock.store;

  } // extraArgs // {
    passthru = {
      inherit src srcLocal workspace workspaceLocal;
      inherit env;
    } // (extraArgs.passthru or {});
  });

  env = buildRustPackage ({
    inherit (rootCrate) name;
    extraCargoConfig = allExtraCargoConfig;

    preConfigure = ''
      ln -s ${srcLocal} src
      ln -s ${workspaceLocal} Cargo.toml
      ln -s ${lock.env} Cargo.lock
    '';

    shellHook = ''
      clean() {
        rm -rf nix-shell.tmp
      }

      setup() {
        mkdir -p nix-shell.tmp
        cd nix-shell.tmp
        configure
      }

      configure() {
        eval "$configurePhase"
      }

      invoke_cargo() {
        cmd="$1"
        shift
        cargo $cmd -j $NIX_BUILD_CORES \
          ${lib.optionalString (!debug) "--release"} \
          --target ${hostPlatform.config} \
          ${lib.concatStringsSep " " (extraArgs.cargoBuildFlags or [])} \
          "$@"
      }

      lock() {
        rm Cargo.lock
        cargo generate-lockfile
        cp Cargo.lock ${lock.env}
      }

      cs() {
        mv nix-shell.tmp/target .
        clean && setup
        mv ../target .
      }

      b() {
        invoke_cargo build "$@"
      }
      t() {
        invoke_cargo test "$@"
      }
      r() {
        invoke_cargo run "$@"
      }
    '';
  } // extraArgs);

in
build
