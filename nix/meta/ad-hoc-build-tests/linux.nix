{ lib, mkShell, buildPackages
, rustc, cargo
, nixToToml, crateUtils, rustTargetName, globalCrates
, stdenv, icecapSrc, fetchCrates
}:

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
    cargo doc \
      --frozen \
      --target-dir target \
      --manifest-path ${src}/Cargo.toml \
      --target ${rustTargetName} \
      $(awk '{print "-p" $$0}' < ${src}/support/crates-for-linux.txt)

    mkdir -p $out/doc
    cp -r target/doc $out/doc/build
    cp -r target/${rustTargetName}/doc $out/doc/target

    # cargo build \
    #   -Z unstable-options \
    #   --frozen \
    #   --target-dir target \
    #   --manifest-path ${src}/Cargo.toml \
    #   --out-dir $out \
    #   --target ${rustTargetName} \
    #   --release \
    #   $(awk '{print "-p" $$0}' < ${src}/support/crates-for-linux.txt)
  '';

  passthru.adHocPath = rustTargetName;
})
