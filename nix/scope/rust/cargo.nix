{ stdenv, pkgconfig, openssl, git, cacert
, crateUtils, fetchCrates, fetchCargoBootstrap
, mkIceCapSrc
, buildPackages, nixToToml

, rustc, cargo
}:

let

  src = (mkIceCapSrc {
    repo = "cargo";
    rev = "3f841f70d4a984c0a6c7cff1027be82e7a7e213d";
    submodules = true;
  }).store;

  cargoVendorConfigRaw = fetchCargoBootstrap {
    inherit src;
    sha256 = "sha256-faWKIPsvPZBWB84SIOIdLZHA2BvcIPM4Ncz42EyeLso=";
  };

  cargoConfig = crateUtils.linkerCargoConfig;

in
stdenv.mkDerivation (crateUtils.baseEnv // rec {
  pname = "cargo";
  version = "nightly";

  inherit src;

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ cargo rustc git cacert pkgconfig ];
  buildInputs = [ openssl ];

  configurePhase = ''
    mkdir -p .cargo
    cat ${nixToToml cargoConfig} > .cargo/config
    cat ${cargoVendorConfigRaw} >> .cargo/config
  '';

  buildPhase = ''
    cargo build --offline --frozen --release \
      --target ${stdenv.hostPlatform.config} \
      -j $NIX_BUILD_CORES
  '';

  installPhase = ''
    find target/${stdenv.hostPlatform.config}/release -maxdepth 1 -type f -executable | xargs -r install -D -t $out/bin
  '';

  passthru = {
    inherit cargoVendorConfigRaw;
  };
})
