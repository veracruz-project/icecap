{ lib, stdenv, buildPackages, buildPlatform, hostPlatform, runCommand, linkFarm, writeText
, rustc, cargo
, fetchCrates, cratesIOIndexCache
, nixToToml, crateUtils, rustTargets, rustTargetName, globalCrates
, icecapSrc
, libsel4, libs

# NOTE wasmtime violates some assertions in core, so debug profile doesn't work
, release ? true

, extraManifest ? {
    profile.release = {
      panic = "abort";
      codegen-units = 1;
      lto = true;
    };
  }
}:

# NOTE broken until we bump the icecap-sysroot branch of rust

with lib;

let
  allImplCrates = attrValues (crateUtils.closure globalCrates.icecap-std-impl);

  srcs = {

    rust = icecapSrc.repo {
      repo = "rust";
      rev = "d23fbea08fc8e0cedd885187910077c97a87262e"; # branch: icecap-sysroot
      submodules = true;
    };

    icecap = {
      store = crateUtils.collectStore allImplCrates;
      env = crateUtils.collectEnv allImplCrates;
    };

    inherit (lib.mapAttrs (_: patch: patch.src) globalCrates._patches)
      dlmalloc libc;
  };

  mkSrc = attr: linkFarm "src" (mapAttrsToList (k: v: { name = k; path = v.${attr}; }) srcs);

  src = mapAttrs (k: _: mkSrc k) {
    store = null;
    env = null;
  };

  lock = runCommand "Cargo.lock" {
    nativeBuildInputs = [
      cargo
    ];
    CARGO_HOME = cratesIOIndexCache;
  } ''
    ln -s ${workspace} Cargo.toml
    ln -s ${src.store} src
    cargo generate-lockfile --offline
    mv Cargo.lock $out
  '';

  ccEnv = {
    "CC_${buildPlatform.config}" = "${buildPackages.stdenv.cc.targetPrefix}cc";
  } // {
    "CC_${rustTargetName}" = "${stdenv.cc.targetPrefix}cc";
  };

  cargoConfig = nixToToml (crateUtils.clobber [
    (fetchCrates lock).config
    {
      build.rustflags = [ "-Z" "force-unstable-if-unmarked" "--sysroot" "/dev/null" ];
      target = {
        ${buildPlatform.config}.linker = "${buildPackages.stdenv.cc.targetPrefix}cc";
      } // {
        ${rustTargetName}.linker = "${stdenv.cc.targetPrefix}cc";
      };
    }
  ]);

  workspace = nixToToml (recursiveUpdate {
    package = {
      name = "sysroot";
      version = "0.0.0";
    };

    lib.path = "${linkFarm "dummy-src" [
      (rec {
        name = "lib.rs";
        path = writeText name ''
        '';
      })
    ]}/lib.rs";

    dependencies.std = {
      features = [ "panic-unwind" ];
      path = "src/rust/src/libstd";
    };

    patch.crates-io = {
      rustc-std-workspace-core = { path = "src/rust/src/tools/rustc-std-workspace-core"; };
      rustc-std-workspace-alloc = { path = "src/rust/src/tools/rustc-std-workspace-alloc"; };
      rustc-std-workspace-std = { path = "src/rust/src/tools/rustc-std-workspace-std"; };
      libc = { path = "src/libc"; };
      dlmalloc = { path = "src/dlmalloc"; };
      icecap-std-impl = { path = "src/icecap/icecap-std-impl"; };
    };
  } extraManifest);

in
lib.fix (self: stdenv.mkDerivation ({
  name = "sysroot";

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ cargo rustc ];
  buildInputs = [
    libsel4
    libs.icecap-runtime
    libs.icecap-utils
  ];

  RUST_TARGET_PATH = rustTargets;
  __CARGO_DEFAULT_LIB_METADATA = "nix-sysroot";

  LIBCLANG_PATH = "${lib.getLib buildPackages.llvmPackages.libclang}/lib";

  phases = [ "configurePhase" "buildPhase" "installPhase" ];

  configurePhase = ''
    mkdir -p .cargo
    ln -s ${cargoConfig} .cargo/config
    ln -s ${lock} Cargo.lock
    ln -s ${workspace} Cargo.toml
    ln -s ${src.store} src

    # HACK
    export BINDGEN_EXTRA_CLANG_ARGS="$NIX_CFLAGS_COMPILE"
  '';

  buildPhase = ''
    cargo build --offline --frozen --target ${rustTargetName} \
      ${optionalString release "--release"}
  '';

  installPhase = ''
    d=$out/lib/rustlib/${rustTargetName}/lib
    mkdir -p $d
    mv target/${rustTargetName}/${if release then "release" else "debug"}/deps/* $d
    d=$out/lib/rustlib/${buildPlatform.config}/lib
    mkdir -p $d
    mv target/${if release then "release" else "debug"}/deps/* $d
  '';

  passthru = {
    inherit lock srcs;

    # Depends on local path (via src.env), so must not affect outer derivation
    env = self.overrideAttrs (attrs: {
      # TODO clean up
      shellHook = ''
        setup() {
          mkdir -p nix-shell.tmp
          cd nix-shell.tmp
          mkdir -p .cargo
          ln -s ${cargoConfig} .cargo/config
          ln -s ${lock} Cargo.lock
          ln -s ${workspace} Cargo.toml
          ln -s ${src.env} src
        }
        clean() {
          rm -rf nix-shell.tmp
        }
        cs() {
          clean && setup
        }
        b() {
          eval "$buildPhase"
        }
      '';
    });
  };
} // ccEnv))
