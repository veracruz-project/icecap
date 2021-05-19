{ lib, hostPlatform, linkFarm
, cargo, emptyDirectory, buildRustPackage, fetchCrates, nixToToml, generateLockfileInternal, crateUtils
, globalArgs ? {}
, globalExtraCargoConfig ? {}
, callPackage
, strace
}:

let
  callPackage_ = callPackage;
in

{ rootCrate, lock ? null
, layers ? []
, debug ? true
, extraCargoConfig ? {}
, extraCargoConfigLink ? {}
, extraManifest ? {}
, extraManifestLocal ? {}
, extraShellHook ? ""
, callPackage ? callPackage_
, extraLastLayerBuildInputs ? [] # TODO generalize
, ...
} @ origArgs:

# NOTE Use this to debug dirty fingerprints
# CARGO_LOG = "cargo::core::compiler::fingerprint=trace";

with lib;

let
  extraManifest_ = extraManifest;
  extraManifestLocal_ = extraManifestLocal;
  lock_ = lock;
in

let
  args = globalArgs // origArgs;

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

  lock = if lock_ != null then lock_ else generateLockfileInternal {
    inherit rootCrate extraManifest;
  };
  cargoVendorConfig = fetchCrates lock;

  extraArgs = builtins.removeAttrs args [
    "layers" "rootCrate" "extraShellHook" "extraManifest" "extraManifestLocal" "extraCargoConfig" "extraCargoConfigLink" "extraLastLayerBuildInputs"
    "callPackage"
  ] // {
    name = rootCrate.name;
    inherit lock;
  };

  baseExtraCargoConfig = crateUtils.clobber [
    (allPropagate.extraCargoConfig or {})
    globalExtraCargoConfig
    extraCargoConfig
    (optionalAttrs (hostPlatform.system == "aarch64-none") { profile.release.panic = "abort"; }) # HACK
  ];

  extraCargoConfigFor = layer: crateUtils.clobber [
    baseExtraCargoConfig
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
          # workspace.members = map (crate: "src/${crate.name}") dummies;
          # workspace.exclude = map (crate: "src/${crate.name}") layer;
        }
        extraManifest
      ]);
    in
      buildRustPackage (extraArgs // {
        inherit cargoVendorConfig;
        extraCargoConfig = extraCargoConfigFor layer;

        dontUnpack = true;
        dontInstall = true;
        dontFixup = true;

        preConfigure = ''
          cp -r --preserve=timestamps ${prev} $out
          chmod -R +w $out
        '';

        # HACK "-Z avoid-dev-deps" for deps of std
        buildPhase = ''
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
      });

in let
  src = crateUtils.collect allCrates;
  srcLocal = crateUtils.collectLocal allCrates;
  allExtraCargoConfig = crateUtils.clobber [
    (extraCargoConfigFor allCrates)
    extraCargoConfigLink
  ];

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

  env = buildRustPackage (extraArgs // {
    inherit cargoVendorConfig;
    extraCargoConfig = allExtraCargoConfig;

    dontUnpack = true;

    # TODO cache at least external deps
      # cp -r --preserve=timestamps ${lastLayer} target
      # chmod -R +w target
    preConfigure = ''
      ${extraArgs.preConfigure or ""}
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
        cargo $cmd -j $NIX_BUILD_CORES --offline --frozen \
          ${lib.optionalString (!debug) "--release"} \
          --target ${hostPlatform.config} \
          ${lib.concatStringsSep " " (extraArgs.cargoBuildFlags or [])} \
          "$@"
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
    '' + extraShellHook;
  });

in
buildRustPackage (extraArgs // {
  buildInputs = (extraArgs.buildInputs or []) ++ extraLastLayerBuildInputs;
} // {
  inherit cargoVendorConfig;
  extraCargoConfig = allExtraCargoConfig;

  nativeBuildInputs = [ strace ];

  dontUnpack = true;

  preConfigure = ''
    ${extraArgs.preConfigure or ""}
    cp -r --preserve=timestamps ${lastLayer} target
    chmod -R +w target
  '';

  cargoBuildFlags = (extraArgs.cargoBuildFlags or []) ++ [
    "--manifest-path" "${manifestDir}/Cargo.toml" "--target-dir=target"
  ];

  passthru = (extraArgs.passthru or {}) // {
    inherit lastLayer env src workspace lock;
    inherit allPropagate;
  };
})
