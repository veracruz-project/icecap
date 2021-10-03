{ lib, stdenv, buildPackages, hostPlatform
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
  # NOTE rustc must precede cargo, because cargoPrebuilt (alias of rustcPrebuilt) contains a different rustc
  nativeBuildInputs = [ rustc cargo git cacert pkgconfig ];
  buildInputs = [ openssl ];

  configurePhase = ''
    mkdir -p .cargo
    cat ${nixToToml cargoConfig} > .cargo/config
    cat ${rustVendoredSources} >> .cargo/config
  '';

  buildPhase = ''
    cargo build -p ${package} --offline --frozen --release \
      --target ${hostPlatform.config} \
      -j $NIX_BUILD_CORES
  '';

  installPhase = ''
    find target/${hostPlatform.config}/release -maxdepth 1 -type f -executable | xargs -r install -D -t $out/bin
  '';
})
