{ stdenv, pkgconfig, openssl, git, cacert
, crateUtils, fetchCrates, fetchCargoBootstrap
, mkIceCapSrc
, buildPackages, nixToToml

, rustc, cargo
}:

let

  src = (mkIceCapSrc {
    repo = "cargo";
    rev = "4a59b73510542acb6312c36b5592fcdcfae4e593";
    submodules = true;
  }).store;

  cargoVendorConfigRaw = fetchCargoBootstrap {
    inherit src;
    sha256 = "sha256-/ulAsQpSaRBi+aaJwEDREGgfbcuggW0wwCtVcUTmFxg=";
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
