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

  flags = lib.concatStringsSep " " (lib.mapAttrsToList (k: _: "-p ${k}") globalCrates._icecapBinsInv);

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
    cargo build \
      --frozen \
      --target-dir target \
      --release \
      --target ${rustTargetName} \
      --manifest-path ${src}/Cargo.toml \
      ${flags} --out-dir $out -Z unstable-options
  '';

})
