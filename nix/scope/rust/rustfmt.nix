{ stdenv, fetchFromGitHub
, fetchCrates, buildRustPackage
}:

buildRustPackage rec {
  pname = "rustfmt";
  version = "1.4.12";
  src = fetchFromGitHub {
    owner = "rust-lang";
    repo = pname;
    rev = "v${version}";
    sha256 = "192c2ln5zb291c5xr6j68930dgm2q7q636l3d1h3pzglmlwwk31x";
  };

  cargoVendorConfig = fetchCrates "${src}/Cargo.lock";
}
