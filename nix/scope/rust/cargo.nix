{ stdenv, pkgconfig, openssl, git, cacert
, crateUtils, fetchCrates, fetchCargoBootstrap
, mkIceCapSrc
, buildPackages, nixToToml

, rustc, cargo
}:

let

  src = builtins.fetchGit {
    url = "https://github.com/rust-lang/rust.git";
    ref = "master";
    rev = "b03ccace573bb91e27625c190a0f7807045a1012";
    submodules = true;
  };

  cargoVendorConfigRaw = fetchCargoBootstrap {
    inherit src;
    sha256 = "sha256-Z3XCOhvOVJ6DT+XpS2hAHubFwgvnaUBRjfaBa8HJ0jo=";
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
    cargo build -p cargo --offline --frozen --release \
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
