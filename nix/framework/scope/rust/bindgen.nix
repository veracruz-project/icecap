{ fetchFromGitHub
, buildRustPackage, fetchCrates
}:

buildRustPackage rec {
  pname = "rust-bindgen";
  version = "0.53.0";
  src = fetchFromGitHub {
    owner = "rust-lang";
    repo = pname;
    rev = "v${version}";
    sha256 = "0ncdk3fdxww0k1x0009gvizpcvnf4n3b7w9cvr4jixvv05jcbnm0";
  };

  extraCargoConfig = (fetchCrates "${src}/Cargo.lock").config;

  doCheck = false;
}
