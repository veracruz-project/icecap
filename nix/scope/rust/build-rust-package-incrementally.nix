{ lib, hostPlatform, buildPlatform, linkFarm, buildPackages, stdenv, mkShell
, cargo, rustc, emptyDirectory, fetchCrates, nixToToml, generateLockfileInternal, crateUtils
}:

{ rootCrate
, layers ? []
, debug ? false
, extraCargoConfig ? {}
, extraManifest ? {}
, extraManifestEnv ? {}
, extraShellHook ? ""
, extraLastLayerBuildInputs ? [] # TODO generalize (inc. extraLastLayerArgs) with overrideAttrs
, extraLastLayerArgs ? {}
, extraArgs ? {}
}:

# NOTE Use this to debug dirty fingerprints
# CARGO_LOG = "cargo::core::compiler::fingerprint=trace";

with lib;

let
  extraManifest_ = extraManifest;
  extraManifestEnv_ = extraManifestEnv;
  release = !debug;
in

let
  allCratesAttrs = crateUtils.closure rootCrate;
  allCrates = lib.attrValues allCratesAttrs;
  allPropagate = crateUtils.clobber (map (x: x.propagate or {}) allCrates);

  extraManifest = crateUtils.clobber [
    (allPropagate.extraManifest or {})
    extraManifest_
  ];

  extraManifestEnv = crateUtils.clobber [
    (allPropagate.extrManifestLocal or {})
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
    # TODO https://github.com/rust-lang/cargo/issues/2930
    # NIX_HACK_CARGO_CONFIG = cargoConfigFor layer;
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
        { name = ".cargo/config"; path = cargoConfigFor layer; }
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

          (cd ${manifestDir} && cargo build -j $NIX_BUILD_CORES --offline --frozen \
            --target ${hostPlatform.config} \
            ${lib.optionalString (!debug) "--release"} \
            -Z avoid-dev-deps \
            --target-dir $out
          )
        '';

        passthru = {
          inherit prev;
        };
      } // commonArgsAfter);

in let
  src = crateUtils.collectStore allCrates;
  srcEnv = crateUtils.collectEnv allCrates;

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
    extraManifestEnv
  ]);

  manifestDir = linkFarm "x" [
    { name = "Cargo.toml"; path = workspace; }
    { name = "src"; path = src; }
    { name = "Cargo.lock"; path = lock; }
    { name = ".cargo/config"; path = cargoConfigFor allCrates; }
  ];

  manifestDirLocal = linkFarm "x" [
    { name = "Cargo.toml"; path = workspaceLocal; }
    { name = "src"; path = srcEnv; }
    { name = "Cargo.lock"; path = lock; }
    { name = ".cargo/config"; path = cargoConfigFor allCrates; }
  ];

  doc = stdenv.mkDerivation (commonArgsFor allCrates // {
    phases = [ "buildPhase" "installPhase" ];

    buildPhase = ''
      target_dir=$(realpath ./target)
      cp -r --preserve=timestamps ${lastLayer} $target_dir
      chmod -R +w $target_dir

      (cd ${manifestDirLocal} && cargo doc -j $NIX_BUILD_CORES --offline --frozen \
        --target ${hostPlatform.config} \
        ${lib.optionalString (!debug) "--release"} \
        -Z avoid-dev-deps \
        --target-dir=$target_dir
      )
    '';

    installPhase = ''
      mkdir $out
      d=target/doc
      [ -d $d ] && mv $d $out/${buildPlatform.config}
      d=target/${hostPlatform.config}/doc
      [ -d $d ] && mv $d $out/${hostPlatform.config}
    '';
  } // commonArgsAfter);

  env = (mkShell (commonArgsFor allCrates // {
    shellHook = ''
      invoke_cargo() {
        cmd="$1"
        shift

        target_dir=$(realpath ./target)

        (cd ${manifestDirLocal} && cargo $cmd -j $NIX_BUILD_CORES --offline --frozen \
          --target ${hostPlatform.config} \
          ${lib.optionalString (!debug) "--release"} \
          -Z avoid-dev-deps \
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
    '' + extraShellHook;
  } // commonArgsAfter // extraLastLayerArgs)).overrideAttrs (attrs: {
    buildInputs = (attrs.buildInputs or []) ++ extraLastLayerBuildInputs;
  });

in
(stdenv.mkDerivation (commonArgsFor allCrates // {
  phases = [ "buildPhase" "installPhase" ];

  buildPhase = ''
    target_dir=$(realpath ./target)
    cp -r --preserve=timestamps ${lastLayer} $target_dir
    chmod -R +w $target_dir

    (cd ${manifestDir} && cargo build -j $NIX_BUILD_CORES --offline --frozen \
      --target ${hostPlatform.config} \
      ${lib.optionalString (!debug) "--release"} \
      -Z avoid-dev-deps \
      --target-dir=$target_dir
    )
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
} // commonArgsAfter // extraLastLayerArgs)).overrideAttrs (attrs: {
  buildInputs = (attrs.buildInputs or []) ++ extraLastLayerBuildInputs;
})

    # echo '${
    #   with lib;
    #   concatMapStrings
    #     (accLayer: concatStringsSep " " (map (x: x.name) accLayer))
    #     allAccumulatedLayers
    # }'
