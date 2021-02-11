{ stdenv, pkgconfig, openssl
, buildRustPackage, fetchCrates, fetchCargoBootstrap
, mkIceCapSrc
}:

buildRustPackage rec {
  pname = "cargo";
  version = "nightly";

  src = (mkIceCapSrc {
    repo = "cargo";
    rev = "2653ff10f572f0c1edb0c97437b21ab9d27e78e3";
    submodules = true;
  }).store;

  # cargoVendorConfig = fetchCrates "${src}/Cargo.lock";
  cargoVendorConfigRaw = fetchCargoBootstrap {
    inherit src;
    sha256 = "sha256-faWKIPsvPZBWB84SIOIdLZHA2BvcIPM4Ncz42EyeLso=";
  };

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ openssl ];

  doCheck = false;
}
