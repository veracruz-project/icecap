{ lib, stdenv, buildPackages, buildPlatform, hostPlatform, runCommand, linkFarm, writeText
, rustc, cargo
, fetchCrates, cratesIOIndexCache
, nixToToml, crateUtils, rustTargets, globalCrates
, icecapSrc

, release ? true
, extraManifest ? {
    profile.release = {
      panic = "abort";
      codegen-units = 1;
      opt-level = 3;
      lto = true;
    };
  }
}:

with lib;

let
  allImplCrates = attrValues (crateUtils.closure globalCrates.icecap-std-impl);

  srcs = {

    rust = icecapSrc.repo {
      repo = "rust";
      rev = "d23fbea08fc8e0cedd885187910077c97a87262e"; # branch: icecap-sysroot

      submodules = true;
      # local = true;
    };

    libc = icecapSrc.repo {
      repo = "minor-patches/rust/libc";
      rev = "1d30655bc094bfdc36cd10547b409f3b3989248c";
    };

    dlmalloc = icecapSrc.repo {
      repo = "minor-patches/rust/dlmalloc";
      # rev = "412ba0f99f5fc1dcd28865988f838db197604e49"; # branch: icecap-supervisee
      rev = "f6759cfed44dc4135eaa43c8c26599357749af39"; # branch: icecap
      # local = true;
    };

    icecap = {
      store = crateUtils.collect allImplCrates;
      env = crateUtils.collectLocal allImplCrates;
    };

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
    "CC_${hostPlatform.config}" = "${stdenv.cc.targetPrefix}cc";
  };

  cargoConfig = nixToToml (crateUtils.clobber [
    (fetchCrates lock).config
    {
      build.rustflags = [ "-Z" "force-unstable-if-unmarked" "--sysroot" "/dev/null" ];
      target = {
        ${buildPlatform.config}.linker = "${buildPackages.stdenv.cc.targetPrefix}cc";
      } // {
        ${hostPlatform.config}.linker = "${stdenv.cc.targetPrefix}cc";
      };
    }
    {
      target.${hostPlatform.config} = crateUtils.clobber (map (crate:
      if crate.buildScript == null then {} else {
        ${"dummy-link-${crate.name}"} = crate.buildScript;
      }) allImplCrates);
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
stdenv.mkDerivation ({
  name = "sysroot";

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ cargo rustc ];

  RUST_TARGET_PATH = rustTargets;
  __CARGO_DEFAULT_LIB_METADATA = "nix-sysroot";

  phases = [ "configurePhase" "buildPhase" "installPhase" ];

  configurePhase = ''
    mkdir -p .cargo
    ln -s ${cargoConfig} .cargo/config
    ln -s ${lock} Cargo.lock
    ln -s ${workspace} Cargo.toml
    ln -s ${src.store} src
  '';

  buildPhase = ''
    cargo build --offline --frozen --target ${hostPlatform.config} \
      ${optionalString release "--release"}
  '';

  installPhase = ''
    d=$out/lib/rustlib/${hostPlatform.config}/lib
    mkdir -p $d
    mv target/${hostPlatform.config}/${if release then "release" else "debug"}/deps/* $d
    d=$out/lib/rustlib/${buildPlatform.config}/lib
    mkdir -p $d
    mv target/${if release then "release" else "debug"}/deps/* $d
  '';

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

  passthru = {
    inherit lock srcs;
  };
} // ccEnv)
