{ lib, hostPlatform, buildPlatform, buildPackages
, stdenv, emptyDirectory, linkFarm, mkShell
, cargo, rustc
, nixToToml, generateLockfileInternal, fetchCrates, crateUtils, rustTargetName
}:

{ rootCrate
, layers ? []
, debug ? false
, extraCargoConfig ? {}
, extraManifest ? {}
, extraManifestEnv ? {}
, extra ? {}
, extraLastLayer ? {}
}:

with lib;

let
  extraManifest_ = extraManifest;
  extraManifestEnv_ = extraManifestEnv;
  extra_ = extra;
  extraLastLayer_ = extraLastLayer;
  release = !debug;
in

let
  extra = if lib.isAttrs extra_ then _: extra_ else extra_;
  extraLastLayer = if lib.isAttrs extraLastLayer_ then _: extraLastLayer_ else extraLastLayer_;
in

let
  allCratesAttrs = crateUtils.closure rootCrate;
  allCrates = lib.attrValues allCratesAttrs;

  extraManifest = crateUtils.clobber [
    extraManifest_
  ];

  extraManifestEnv = crateUtils.clobber [
    extraManifestEnv_
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
      expandLayer = layer: concatAttrs (map (key: crateUtils.closure (toCrate key)) layer);
    in
      reverseList (map attrValues (accumulate (map expandLayer layers)));

  listMinus = x: y: filter (z: !(elem z y)) x;

  lastLayer = f allAccumulatedLayers;

  lock = generateLockfileInternal {
    inherit extraManifest;
    rootCrates = [ rootCrate ];
  };

  baseCargoConfig = crateUtils.clobber [
    (fetchCrates lock).config
    crateUtils.baseCargoConfig
    extraCargoConfig
  ];

  cargoConfigFor = layer: nixToToml (crateUtils.clobber [
    baseCargoConfig
  ]);

  baseCommonArgs = crateUtils.baseEnv // {
    name = rootCrate.name;
    depsBuildBuild = [ buildPackages.stdenv.cc ];
    nativeBuildInputs = [ cargo rustc ];
  };

  commonArgsFor = layer: baseCommonArgs // {
    # TODO https://github.com/rust-lang/cargo/issues/2930
    # NIX_HACK_CARGO_CONFIG = cargoConfigFor layer;
  };

  workspaceCommon = {
    workspace.resolver = "2";
  };

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
        { name = ".cargo/config"; path = cargoConfigFor layer; }
      ];

      workspace = nixToToml (crateUtils.clobber [
        workspaceCommon
        {
          workspace.members = [ "src/${rootCrate.name}" ];
        }
        extraManifest
      ]);
    in
      (stdenv.mkDerivation (commonArgsFor layer // {
        phases = [ "buildPhase" ];

        # HACK "-Z avoid-dev-deps" for deps of std
        buildPhase = ''
          runHook preBuild

          cp -r --preserve=timestamps ${prev} $out
          chmod -R +w $out

          (cd ${manifestDir} && cargo build -j $NIX_BUILD_CORES --offline --frozen \
            -p ${rootCrate.name} \
            --target ${rustTargetName} \
            ${lib.optionalString (!debug) "--release"} \
            --target-dir $out
          )
        '';

        passthru = {
          inherit prev;
        };
      })).overrideAttrs extra;

in let
  src = crateUtils.collectStore allCrates;
  srcEnv = crateUtils.collectEnv allCrates;

  workspace = nixToToml (crateUtils.clobber [
    workspaceCommon
    {
      workspace.members = [ "src/${rootCrate.name}" ];
    }
    extraManifest
  ]);

  workspaceEnv = nixToToml (crateUtils.clobber [
    workspaceCommon
    {
      workspace.members = [ "src/${rootCrate.name}" ];
    }
    extraManifest
    extraManifestEnv
  ]);

  manifestDir = linkFarm "x" [
    { name = "Cargo.toml"; path = workspace; }
    { name = "src"; path = src; }
    { name = "Cargo.lock"; path = lock; }
    { name = ".cargo/config"; path = cargoConfigFor allCrates; }
  ];

  manifestDirEnv = linkFarm "x" [
    { name = "Cargo.toml"; path = workspaceEnv; }
    { name = "src"; path = srcEnv; }
    { name = "Cargo.lock"; path = lock; }
    { name = ".cargo/config"; path = cargoConfigFor allCrates; }
  ];

  doc = (stdenv.mkDerivation (commonArgsFor allCrates // {
    phases = [ "buildPhase" "installPhase" ];

    buildPhase = ''
      runHook preBuild

      target_dir=$(realpath ./target)
      cp -r --preserve=timestamps ${lastLayer} $target_dir
      chmod -R +w $target_dir

      (cd ${manifestDir} && cargo doc -j $NIX_BUILD_CORES --offline --frozen \
        -p ${rootCrate.name} \
        --target ${rustTargetName} \
        ${lib.optionalString (!debug) "--release"} \
        --target-dir=$target_dir
      )
    '';

    installPhase = ''
      mkdir $out
      d=target/doc
      [ -d $d ] && mv $d $out/${buildPlatform.config}
      d=target/${rustTargetName}/doc
      [ -d $d ] && mv $d $out/${rustTargetName}
    '';
  })).overrideAttrs extra;

  env = ((mkShell (commonArgsFor allCrates // {
    shellHook = ''
      invoke_cargo() {
        cmd="$1"
        shift

        target_dir=$(realpath ./target)

        (cd ${manifestDirEnv} && cargo $cmd -j $NIX_BUILD_CORES --offline --frozen \
          -p ${rootCrate.name} \
          --target ${rustTargetName} \
          ${lib.optionalString (!debug) "--release"} \
          --target-dir=$target_dir \
          "$@"
        )
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
  })).overrideAttrs extra).overrideAttrs extraLastLayer;

in
((stdenv.mkDerivation (commonArgsFor allCrates // {
  phases = [ "buildPhase" "installPhase" ];

  buildPhase = ''
    runHook preBuild

    target_dir=$(realpath ./target)
    cp -r --preserve=timestamps ${lastLayer} $target_dir
    chmod -R +w $target_dir

    (cd ${manifestDir} && cargo build -j $NIX_BUILD_CORES --offline --frozen \
      -p ${rootCrate.name} \
      --target ${rustTargetName} \
      ${lib.optionalString (!debug) "--release"} \
      --target-dir=$target_dir
    )
  '';

  installPhase = ''
    lib_re='.*\.\(so.[0-9.]+\|so\|a\|dylib\)'
    find target/${rustTargetName}/${if release then "release" else "debug"} -maxdepth 1 \
      -regex "$lib_re" \
      | xargs -r install -D -t $out/lib
    find target/${rustTargetName}/${if release then "release" else "debug"} -maxdepth 1 \
      -type f -executable -not -regex "$lib_re" \
      | xargs -r install -D -t $out/bin
  '';

  passthru = {
    inherit env doc;
    inherit lastLayer;
    inherit src workspace lock;
  };
})).overrideAttrs extra).overrideAttrs extraLastLayer

# NOTE Use this to debug dirty fingerprints
# CARGO_LOG = "cargo::core::compiler::fingerprint=trace";

# TODO for intermediate steps, show message listing current layers:
# echo '${
#   with lib;
#   concatMapStrings
#     (accLayer: concatStringsSep " " (map (x: x.name) accLayer))
#     allAccumulatedLayers
# }'
