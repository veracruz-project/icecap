{ lib, stdenvNoCC, pkgs, targetPackages, buildPackages
, buildPlatform, hostPlatform, targetPlatform
, runCommand, linkFarm
, fetchFromGitHub
, file, which
, cmake, ninja, python3

, nixToToml, crateUtils, fetchCrates, fetchCargoBootstrap, rustTargets
, rustc, cargo, rustfmt
}:

let

  src = builtins.fetchGit {
    url = "https://github.com/rust-lang/rust.git";
    ref = "master";
    rev = "b03ccace573bb91e27625c190a0f7807045a1012";
    submodules = true;
  };

  vendored-sources = (fetchCargoBootstrap {
    inherit src;
    sha256 = "sha256-Z3XCOhvOVJ6DT+XpS2hAHubFwgvnaUBRjfaBa8HJ0jo=";
  }).directory;

  python = "${buildPackages.python3}/bin/python3";

  # https://github.com/rust-lang/rust/issues/34486: llvm-config fails to report -lffi
  configToml = nixToToml (crateUtils.clobber [
    {
      llvm.link-shared = true;

      build = {
        build = buildPlatform.config;
        host = [ hostPlatform.config ];
        target = [ hostPlatform.config targetPlatform.config ];

        rustc = "${rustc}/bin/rustc";
        cargo = "${cargo}/bin/cargo";
        rustfmt = "${rustfmt}/bin/rustfmt";
        inherit python;

        docs = false;
        compiler-docs = false;
        sanitizers = false;
        profiler = false;

        vendor = true;
        # verbose = 2;
      };

      install.prefix = "@out@";

      rust.lld = true;
      rust.default-linker = "/var/empty/nope";

      # TODO no cc on bare?

      target = lib.foldr (x: y: x // y) {} (map (pkgs_:
        let
          env = pkgs_.stdenv;
          llvmPkgs = if env.hostPlatform.config == buildPlatform.config
            then (if buildPlatform.config == hostPlatform.config then pkgs else pkgs_)
            else (if env.hostPlatform.config == hostPlatform.config then pkgs_ else null);
        in {
          ${env.hostPlatform.config} = lib.optionalAttrs (!env.hostPlatform.isWasm) {
            cc     = "${env.cc}/bin/${env.cc.targetPrefix}cc";
            linker = "${env.cc}/bin/${env.cc.targetPrefix}cc";
            cxx    = "${env.cc}/bin/${env.cc.targetPrefix}c++";
            ar     = "${env.cc.bintools.bintools}/bin/${env.cc.bintools.bintools.targetPrefix}ar";
            ranlib = "${env.cc.bintools.bintools}/bin/${env.cc.bintools.bintools.targetPrefix}ranlib";
          } // lib.optionalAttrs env.hostPlatform.isWasm {
            ar     = "${env.cc.bintools.bintools}/bin/${env.cc.targetPrefix}ar";
            ranlib = "${env.cc.bintools.bintools}/bin/${env.cc.targetPrefix}ranlib";
          } // lib.optionalAttrs (env.hostPlatform.config == "aarch64-none-elf") {
            linker = "${env.cc}/bin/${env.cc.targetPrefix}ld";
            no-std = true;
          } // lib.optionalAttrs env.hostPlatform.isMusl {
            musl-root = "${env.cc.libc}";
          };
      }) [ buildPackages targetPackages ]);
    }
  ]);

  # TODO local-build = true for cross

in stdenvNoCC.mkDerivation rec {
  pname = "rustc";
  version = "nightly";
  inherit src;

  nativeBuildInputs = [ file which cmake ninja python3 ];
  RUST_TARGET_PATH = rustTargets;

  phases = [ "unpackPhase" "patchPhase" "configurePhase" "buildPhase" "installPhase" ];

  postPatch = ''
    patchShebangs src/etc
  '';

  configurePhase = ''
    substitute ${configToml} config.toml --replace @out@ $out
    ln -s ${vendored-sources} vendor
  '';

  buildPhase = ''
    ${python} x.py build --jobs $NIX_BUILD_CORES
  '';

  installPhase = ''
    mkdir $out
    ${python} x.py install
  '';

  passthru = {
    inherit configToml vendored-sources;
  };
}
