{ lib, stdenvNoCC, pkgs, targetPackages, buildPackages
, buildPlatform, hostPlatform, targetPlatform
, runCommand, linkFarm
, fetchFromGitHub
, file, which
, cmake

, mkIceCapSrc
, nixToToml, crateUtils, fetchCrates, fetchCargoBootstrap, rustTargets
, rustc, cargo, rustfmt
}:

let

  src = (mkIceCapSrc {
    repo = "rust";
    rev = "df10c3238668af9108f33c7005ce1ac5875e335b";
    submodules = true;
  }).store;

  # inherit (fetchCrates "${src}/Cargo.lock") vendored-sources;

  vendored-sources = (fetchCargoBootstrap {
    inherit src;
    sha256 = "sha256-DgA0iSLV51SzB0uHHRVZ+rZWPGQvqCxHMl/UdGh6hEg=";
  }).directory;

  python = "${buildPackages.python2}/bin/python2.7";

  # https://github.com/rust-lang/rust/issues/34486: llvm-config fails to report -lffi
  # gdb = "${python2.__spliced.buildPackages.gdb}/bin/gdb";
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

      # rust.rpath = true;
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
          } // lib.optionalAttrs (llvmPkgs != null) {
            llvm-config = "${llvmPkgs.llvm_9}/bin/llvm-config";
          } // lib.optionalAttrs (env.hostPlatform.config == "aarch64-none-elf") {
            linker = "${env.cc}/bin/${env.cc.targetPrefix}ld";
            no-std = true;
          } // lib.optionalAttrs env.hostPlatform.isMusl {
            musl-root = "${env.cc.libc}";
          } // lib.optionalAttrs env.hostPlatform.isWasi {
            inherit wasi-root;
            # wasi-root = "${env.cc.libc}";
          };
      }) [ buildPackages targetPackages ]);
    }
    (lib.optionalAttrs targetPlatform.isWasm {
      rust.lld = true;
    })
  ]);

  # TODO local-build = true for cross

  wasi-root = linkFarm "wasi-root" [
    { name = "lib/wasm32-wasi"; path = "${targetPackages.stdenv.cc.libc}/lib"; }
  ];

  # wasi-root = runCommand "wasi-root" {} ''
  #   mkdir -p $out/lib
  #   ln -s ${targetPackages.stdenv.cc.libc} $out/lib/wasm32-wasi
  # '';

in stdenvNoCC.mkDerivation (rec {
  pname = "rustc";
  version = "nightly";
  inherit src;

  nativeBuildInputs = [ file which ] ++ lib.optionals targetPlatform.isWasm [ cmake ];
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
} // lib.optionalAttrs targetPlatform.isWasm {
  RUST_BACKTRACE = 1;
})
