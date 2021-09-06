{ lib, stdenvNoCC
, buildPlatform, hostPlatform
, file, which
, cmake, ninja, python3

, rustSource, rustVendoredSources, rustTargets
, nixToToml, fetchCargoBootstrap

, rustc, cargo, rustfmt

, targets
}:

let

  configToml = nixToToml {

    llvm.link-shared = true;

    build = {
      build = buildPlatform.config;
      host = [ hostPlatform.config ];
      target = map (target: target.hostPlatform.config) targets;

      rustc = "${rustc}/bin/rustc";
      cargo = "${cargo}/bin/cargo";
      rustfmt = "${rustfmt}/bin/rustfmt";

      docs = false;
      compiler-docs = false;
      sanitizers = false;
      profiler = false;

      vendor = true;

      # verbose = 2;

      # TODO local-rebuild = true for cross?
    };

    install.prefix = "@out@";

    # TODO evaluate or drop
    rust.lld = true;

    rust.default-linker = "/var/empty/nope";

    target = lib.foldr (x: y: x // y) {} (map (pkgs_:
      let
        env = pkgs_.stdenv;
      in {
        ${env.hostPlatform.config} = lib.optionalAttrs (!env.hostPlatform.isWasm) {
          cc     = "${env.cc}/bin/${env.cc.targetPrefix}cc";
          linker = "${env.cc}/bin/${env.cc.targetPrefix}cc";
          cxx    = "${env.cc}/bin/${env.cc.targetPrefix}c++";
          ar     = "${env.cc.bintools.bintools}/bin/${env.cc.bintools.bintools.targetPrefix}ar";
          ranlib = "${env.cc.bintools.bintools}/bin/${env.cc.bintools.bintools.targetPrefix}ranlib";
        # TODO remove
        } // lib.optionalAttrs env.hostPlatform.isWasm {
          ar     = "${env.cc.bintools.bintools}/bin/${env.cc.targetPrefix}ar";
          ranlib = "${env.cc.bintools.bintools}/bin/${env.cc.targetPrefix}ranlib";
        } // lib.optionalAttrs (env.hostPlatform.config == "aarch64-none-elf") {
          linker = "${env.cc}/bin/${env.cc.targetPrefix}ld";
          no-std = true;
        } // lib.optionalAttrs env.hostPlatform.isMusl {
          musl-root = "${env.cc.libc}";
        };
    }) targets);
  };

in stdenvNoCC.mkDerivation rec {
  pname = "rustc";
  version = "nightly";
  src = rustSource;

  nativeBuildInputs = [ file which cmake ninja python3 ];
  RUST_TARGET_PATH = rustTargets;

  phases = [ "unpackPhase" "patchPhase" "configurePhase" "buildPhase" "installPhase" ];

  postPatch = ''
    patchShebangs src/etc
  '';

  configurePhase = ''
    substitute ${configToml} config.toml --replace @out@ $out
    ln -s ${rustVendoredSources.directory} vendor
  '';

  buildPhase = ''
    python x.py build --jobs $NIX_BUILD_CORES
  '';

  installPhase = ''
    mkdir $out
    python x.py install

    python x.py dist rustc-dev
    cp build/dist/rustc-dev*tar.gz $out
  '';

  passthru = {
    inherit configToml;
  };
}

    # install rustc-dev components. Necessary to build rls, clippy...
    # tar xf build/dist/rustc-dev*tar.gz
    # cp -r rustc-dev*/rustc-dev*/lib/* $out/lib/
    # rm $out/lib/rustlib/install.log
    # for m in $out/lib/rustlib/manifest-rust*
    # do
    #   sort --output=$m < $m
    # done
