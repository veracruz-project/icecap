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

  # Informed by https://github.com/rust-lang/rust/blob/master/src/ci/run.sh

  configToml = nixToToml {

    llvm.link-shared = true;

    build = {
      build = buildPlatform.config;
      host = [ hostPlatform.config ];
      target = map (target: target.icecap.rustTargetName) targets;

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

    # TODO keep for safety?
    # rust.default-linker = "/var/empty/nope";

    rust.codegen-units-std = 1;

    target = lib.foldr (x: y: x // y) {} (map (pkgs_:
      let
        env = pkgs_.stdenv;
      in {
        ${pkgs_.icecap.rustTargetName} = {
          cc     = "${env.cc}/bin/${env.cc.targetPrefix}cc";
          linker = "${env.cc}/bin/${env.cc.targetPrefix}cc";
          cxx    = "${env.cc}/bin/${env.cc.targetPrefix}c++";
          ar     = "${env.cc.bintools.bintools}/bin/${env.cc.bintools.targetPrefix}ar";
          ranlib = "${env.cc.bintools.bintools}/bin/${env.cc.bintools.targetPrefix}ranlib";
        } // lib.optionalAttrs env.hostPlatform.isNone {
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
