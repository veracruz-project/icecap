{ lib, stdenv, buildPackages
, pkgconfig, openssl, git, cacert

, rustSource, rustVendoredSources
, nixToToml, crateUtils

, rustc, cargo
}:

{ package }:

let
  cargoConfig = crateUtils.linkerCargoConfig;

in
stdenv.mkDerivation (crateUtils.baseEnv // rec {
  pname = package;
  version = "nightly";
  src = rustSource;

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ cargo rustc git cacert pkgconfig ];
  buildInputs = [ openssl ];

  configurePhase = ''
    mkdir -p .cargo
    cat ${nixToToml cargoConfig} > .cargo/config
    cat ${rustVendoredSources} >> .cargo/config
  '';

  buildPhase = ''
    cargo build -p ${package} --offline --frozen --release \
      --target ${stdenv.hostPlatform.config} \
      -j $NIX_BUILD_CORES
  '';

  installPhase = ''
    find target/${stdenv.hostPlatform.config}/release -maxdepth 1 -type f -executable | xargs -r install -D -t $out/bin
  '';
})
