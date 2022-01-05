{ lib, mkShell, buildPackages
, rustc, cargo
, nixToToml, crateUtils, rustTargetName, globalCrates
, stdenv, icecapSrc, fetchCrates
}:

{ build ? false, release ? false, doc ? false, docDeps ? false }:

let

  lock = src + "/Cargo.lock";

  cargoConfig = nixToToml (crateUtils.clobber [
    crateUtils.baseCargoConfig
    (fetchCrates lock).config
  ]);

  src = (icecapSrc.relativeSplit "rust").store;

in stdenv.mkDerivation (crateUtils.baseEnv // {
  name = "test";

  phases = [ "configurePhase" "buildPhase" ];

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ cargo rustc ];

  configurePhase = ''
    mkdir .cargo
    ln -s ${cargoConfig} .cargo/config
  '';

  buildPhase = ''
    package_args=$(awk '{print "-p" $$0}' < ${src}/support/crates-for-linux.txt)

  '' + lib.optionalString build ''
    cargo build \
      -Z unstable-options \
      --frozen \
      --target-dir target \
      --manifest-path ${src}/Cargo.toml \
      --out-dir $out/bin \
      --target ${rustTargetName} \
      ${lib.optionalString release "--release"} \
      $package_args

  '' + lib.optionalString doc ''
    RUSTDOCFLAGS="-Z unstable-options --enable-index-page" \
      cargo doc \
        --frozen \
        --target-dir target \
        --manifest-path ${src}/Cargo.toml \
        --target ${rustTargetName} \
        ${lib.optionalString (!docDeps) "--no-deps"} \
        $package_args

    mkdir -p $out/doc
    cp -r target/doc $out/doc/build
    cp -r target/${rustTargetName}/doc $out/doc/host
  '';

  passthru.worldPath = rustTargetName;
})
