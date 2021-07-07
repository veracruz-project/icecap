{ lib, hostPlatform, buildPlatform, linkFarm, buildPackages, stdenv, mkShell
, cargo, rustc, emptyDirectory, fetchCrates, nixToToml, generateLockfileInternal, crateUtils
}:

{ rootCrate
, layers ? []
, debug ? true
, extraCargoConfig ? {}
, extraManifest ? {}
, extraManifestLocal ? {}
, extraShellHook ? ""
, extraLastLayerBuildInputs ? [] # TODO generalize
, extraArgs ? {}
}:

# NOTE Use this to debug dirty fingerprints
# CARGO_LOG = "cargo::core::compiler::fingerprint=trace";

with lib;

let
  extraManifest_ = extraManifest;
  extraManifestLocal_ = extraManifestLocal;
  release = !debug;
in

let
  allCratesAttrs = crateUtils.flatDepsWithRoot rootCrate;
  allCrates = lib.attrValues allCratesAttrs;
  allPropagate = crateUtils.clobber (map (x: x.propagate or {}) allCrates);

  extraManifest = crateUtils.clobber [
    (allPropagate.extraManifest or {})
    extraManifest_
  ];

  extraManifestLocal = crateUtils.clobber [
    (allPropagate.extrManifestLocal or {})
    extraManifestLocal_
  ];

  toCrate = key: if isAttrs key then key else allCratesAttrs.${key};
  concatAttrs = fold (x: y: x // y) {};

  accumulate = with lib;
    let
      f = acc: prev: xs:
        if length xs == 0
        then acc
        else
          let
            prev' = prev // head xs;
            acc' = acc ++ [ prev' ];
          in
            f acc' prev' (tail xs);
    in
      f [] {};

  allAccumulatedLayers =
    let
      expandLayer = layer: concatAttrs (map (key: crateUtils.flatDepsWithRoot (toCrate key)) layer);
    in
      reverseList (map attrValues (accumulate (map expandLayer layers)));

  listMinus = x: y: filter (z: !(elem z y)) x;

  lastLayer = f allAccumulatedLayers;

  lock = generateLockfileInternal {
    inherit rootCrate extraManifest;
  };
  cargoVendorConfig = fetchCrates lock;

  baseCargoConfig = crateUtils.clobber [
    cargoVendorConfig.config
    crateUtils.baseCargoConfig
    (optionalAttrs (hostPlatform.system == "aarch64-none") { profile.release.panic = "abort"; }) # HACK
    (allPropagate.extraCargoConfig or {})
    extraCargoConfig
  ];

  cargoConfigFor = layer: nixToToml (crateUtils.clobber [
    baseCargoConfig
    {
      target.${hostPlatform.config} = crateUtils.clobber (map (crate:
      if crate.buildScript == null then {} else {
        ${"dummy-link-${crate.name}"} = {};
      }) allCrates);
    }
    {
      target.${hostPlatform.config} = crateUtils.clobber (map (crate:
      if crate.buildScript == null then {} else {
        ${"dummy-link-${crate.name}"} = crate.buildScript;
      }) layer);
    }
  ]);

  baseCommonArgs = crateUtils.baseEnv // {
    name = rootCrate.name;
    depsBuildBuild = [ buildPackages.stdenv.cc ] ++ (extraArgs.depsBuildBuild or []);
    nativeBuildInputs = [ cargo rustc /* rustc for rustdoc */ ] ++ (extraArgs.nativeBuildInputs or []);
  };

  commonArgsFor = layer: baseCommonArgs // {
    NIX_HACK_CARGO_CONFIG = cargoConfigFor layer;
  };

  commonArgsAfter = builtins.removeAttrs extraArgs [
    "depsBuildBuild" "nativeBuildInputs" "passthru"
  ];

  f = accumulatedLayers: if length accumulatedLayers == 0 then emptyDirectory else
    let
      layer = head accumulatedLayers;
      prev = f (tail accumulatedLayers);
      dummies = listMinus allCrates layer;
      src = crateUtils.collectDummies layer dummies;

      manifestDir = linkFarm "x" [
        { name = "Cargo.toml"; path = workspace; }
        { name = "src"; path = src; }
        { name = "Cargo.lock"; path = lock; }
      ];

      workspace = nixToToml (crateUtils.clobber [
        {
          workspace.members = [ "src/${rootCrate.name}" ];
        }
        extraManifest
      ]);
    in
      stdenv.mkDerivation (commonArgsFor layer // {
        phases = [ "buildPhase" ];

        # HACK "-Z avoid-dev-deps" for deps of std
        buildPhase = ''
          cp -r --preserve=timestamps ${prev} $out
          chmod -R +w $out

          cargo build -j $NIX_BUILD_CORES --offline --frozen \
            --target ${hostPlatform.config} \
            ${lib.optionalString (!debug) "--release"} \
            -Z avoid-dev-deps \
            --manifest-path ${manifestDir}/Cargo.toml \
            --target-dir $out
        '';

        passthru = {
          inherit prev;
        };
      } // commonArgsAfter);

in let
  src = crateUtils.collect allCrates;
  srcLocal = crateUtils.collectLocal allCrates;

  workspace = nixToToml (crateUtils.clobber [
    {
      workspace.members = [ "src/${rootCrate.name}" ];
    }
    extraManifest
  ]);

  workspaceLocal = nixToToml (crateUtils.clobber [
    {
      workspace.members = [ "src/${rootCrate.name}" ];
    }
    extraManifest
    extraManifestLocal
  ]);

  manifestDir = linkFarm "x" [
    { name = "Cargo.toml"; path = workspace; }
    { name = "src"; path = src; }
    { name = "Cargo.lock"; path = lock; }
  ];

  manifestDirLocal = linkFarm "x" [
    { name = "Cargo.toml"; path = workspaceLocal; }
    { name = "src"; path = srcLocal; }
    { name = "Cargo.lock"; path = lock; }
  ];

  doc = stdenv.mkDerivation (commonArgsFor allCrates // {
    phases = [ "buildPhase" "installPhase" ];

    buildPhase = ''
      cp -r --preserve=timestamps ${lastLayer} target
      chmod -R +w target

      cargo doc -j $NIX_BUILD_CORES --offline --frozen \
        --target ${hostPlatform.config} \
        ${lib.optionalString (!debug) "--release"} \
        -Z avoid-dev-deps \
        --target-dir=target \
        --manifest-path ${manifestDir}/Cargo.toml
    '';

    installPhase = ''
      mkdir $out
      d=target/doc
      [ -d $d ] && mv $d $out/${buildPlatform.config}
      d=target/${hostPlatform.config}/doc
      [ -d $d ] && mv $d $out/${hostPlatform.config}
    '';
  } // commonArgsAfter);

  env = mkShell (commonArgsFor allCrates // {
    shellHook = ''
      invoke_cargo() {
        cmd="$1"
        shift
        cargo $cmd -j $NIX_BUILD_CORES --offline --frozen \
          --target ${hostPlatform.config} \
          ${lib.optionalString (!debug) "--release"} \
          -Z avoid-dev-deps \
          --target-dir=target \
          --manifest-path ${manifestDirLocal}/Cargo.toml \
          "$@"
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
    '' + extraShellHook;
  } // commonArgsAfter);

in
stdenv.mkDerivation (commonArgsFor allCrates // {
  phases = [ "buildPhase" "installPhase" ];

  buildPhase = ''
    cp -r --preserve=timestamps ${lastLayer} target
    chmod -R +w target

    cargo build -j $NIX_BUILD_CORES --offline --frozen \
      --target ${hostPlatform.config} \
      ${lib.optionalString (!debug) "--release"} \
      -Z avoid-dev-deps \
      --target-dir=target \
      --manifest-path ${manifestDir}/Cargo.toml
  '';

  installPhase = ''
    lib_re='.*\.\(so.[0-9.]+\|so\|a\|dylib\)'
    find target/${hostPlatform.config}/${if release then "release" else "debug"} -maxdepth 1 -type f -executable -not -regex "$lib_re" | xargs -r install -D -t $out/bin
    find target/${hostPlatform.config}/${if release then "release" else "debug"} -maxdepth 1                          -regex "$lib_re" | xargs -r install -D -t $out/lib
  '';

  passthru = (extraArgs.passthru or {}) // {
    inherit lastLayer env doc src workspace lock;
    inherit allPropagate;
  };
} // commonArgsAfter)

    # echo '${
    #   with lib;
    #   concatMapStrings
    #     (accLayer: concatStringsSep " " (map (x: x.name) accLayer))
    #     allAccumulatedLayers
    # }'
