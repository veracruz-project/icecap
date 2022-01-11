{ lib, stdenv, buildPackages, buildPlatform, hostPlatform, runCommand, linkFarm, writeText
, rustc, cargo
, fetchCrates, cratesIOIndexCache
, nixToToml, crateUtils, rustTargets, rustTargetName, globalCrates
, icecapSrc
, libsel4, userC

, release ? true

, extraManifest ? {
    profile.release = {
      codegen-units = 1;
      lto = true;
      opt-level = 3;
      debug = 0;
      # NOTE at least at one point, wasmtime was violating some debug assertions in core
      debug-assertions = true;
    };
  }
}:

with lib;

let
  allImplCrates = attrValues (crateUtils.closure globalCrates.icecap-std-impl);

  srcs = {

    rust = icecapSrc.repo {
      repo = "rust";
      rev = "564dac541463c35b1e2028e759f49f21e1374ddf"; # branch: icecap-sysroot
      submodules = true;
    };

    icecap = {
      store = crateUtils.collectStore allImplCrates;
      env = crateUtils.collectEnv allImplCrates;
    };

    inherit (lib.mapAttrs (_: patch: patch.src) globalCrates._patches)
      dlmalloc libc;
  };

  mkSplit = f: mapAttrs (k: _: f k) {
    store = null;
    env = null;
  };

  srcSplit = mkSplit (attr: linkFarm "src" (mapAttrsToList (k: v: { name = k; path = v.${attr}; }) srcs));

  lock = runCommand "Cargo.lock" {
    nativeBuildInputs = [
      cargo
    ];
    CARGO_HOME = cratesIOIndexCache;
  } ''
    ln -s ${workspace.store} Cargo.toml
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
      target = {
        ${buildPlatform.config}.linker = "${buildPackages.stdenv.cc.targetPrefix}cc";
      } // {
        ${rustTargetName} = {
          linker = "${stdenv.cc.targetPrefix}cc";
          rustflags = [
            "-C" "force-unwind-tables=yes" "-C" "embed-bitcode=yes"
            "-Z" "force-unstable-if-unmarked"
            "--sysroot" "/dev/null"
          ];
        };
      };
    }
  ]);

  workspace = mkSplit (attr:
    let
      src = srcSplit.${attr};
    in
      nixToToml (recursiveUpdate {
        workspace.resolver = "2";

        package = {
          name = "sysroot";
          version = "0.0.0";
          edition = "2018";
        };

        lib.path = "${linkFarm "dummy-src" [
          (rec {
            name = "lib.rs";
            path = writeText name ''
            '';
          })
        ]}/lib.rs";

        dependencies = {
          std.path = "${src}/rust/library/std";
          # Hacks to get std to depend on our patches.
          libc = "=0.2.108";
          dlmalloc = "=0.1.3";
        };

        patch.crates-io = {
          rustc-std-workspace-core = { path = "${src}/rust/library/rustc-std-workspace-core"; };
          rustc-std-workspace-alloc = { path = "${src}/rust/library/rustc-std-workspace-alloc"; };
          rustc-std-workspace-std = { path = "${src}/rust/library/rustc-std-workspace-std"; };
          libc = { path = "${src}/libc"; };
          dlmalloc = { path = "${src}/dlmalloc"; };
          icecap-std-impl = { path = "${src}/icecap/icecap-std-impl"; };
        };
      } extraManifest));

in
lib.fix (self: stdenv.mkDerivation ({
  name = "sysroot";

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ cargo rustc ];
  buildInputs = [
    libsel4
    userC.nonRootLibs.icecap-runtime
    userC.nonRootLibs.icecap-utils
  ];

  RUST_TARGET_PATH = rustTargets;

  LIBCLANG_PATH = "${lib.getLib buildPackages.llvmPackages.libclang}/lib";

  phases = [ "configurePhase" "buildPhase" "installPhase" ];

  configurePhase = ''
    mkdir -p .cargo
    ln -s ${cargoConfig} .cargo/config
    ln -s ${lock} Cargo.lock
    ln -s ${workspace.store} Cargo.toml
  '';

  buildPhase = ''
    RUSTC_BOOTSTRAP=1 \
    __CARGO_DEFAULT_LIB_METADATA=nix-sysroot \
    BINDGEN_EXTRA_CLANG_ARGS="$NIX_CFLAGS_COMPILE" \
      cargo build \
        -Z unstable-options \
        -Z binary-dep-depinfo \
        --offline --frozen \
        --target ${rustTargetName} \
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
          ln -s ${workspace.env} Cargo.toml
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
