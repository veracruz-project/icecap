{ buildRustPackage
, fetchFromGitHub
, fetchCrates
, libfdt
}:

buildRustPackage rec {
  pname = "firecracker";
  version = "0.20.0";
  src = fetchFromGitHub {
    owner = "firecracker-microvm";
    repo = pname;
    rev = "v${version}";
    sha256 = "1h5zz2ayck6mvzqg7q7qlk5bpkv1sv529cwwij52f0w91pnchfi6";
  };

  cargoVendorConfig = fetchCrates "${src}/Cargo.lock";

  buildInputs = [ libfdt ];

  prePatch = ''
    rm .cargo/config
  '';

}
