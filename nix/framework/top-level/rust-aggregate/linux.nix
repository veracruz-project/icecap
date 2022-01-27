{ lib, mkShell, buildPackages
, rustc, cargo
, nixToToml, crateUtils, rustTargetName, globalCrates
, stdenv, icecapSrc, fetchCrates
}:

{ build ? false, release ? false, doc ? false, docDeps ? false, docAll ? false }:

let

  lock = src + "/Cargo.lock";

  cargoConfig = nixToToml (crateUtils.clobber [
    crateUtils.baseCargoConfig
    crateUtils.denyWarningsCargoConfig # NOTE this may become infeasible for dependencies
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
    package_args_fewer_docs=$(comm -1 -2 ${src}/support/crates-for-linux.txt ${src}/support/crates-for-docs.txt | awk '{print "-p" $$0}')

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
        ${if docAll then "$package_args" else "$package_args_fewer_docs"}

    mkdir -p $out/doc
    cp -r target/doc $out/doc/build
    cp -r target/${rustTargetName}/doc $out/doc/host
  '';

  passthru.worldPath = rustTargetName;
})
