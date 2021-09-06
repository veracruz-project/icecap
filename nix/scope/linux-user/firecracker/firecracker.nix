{ lib, hostPlatform
, icecapSrc
, buildRustPackage
, fetchCrates
, libfdt
}:

buildRustPackage rec {
  pname = "firecracker";
  version = "0.25.0";
  src = icecapSrc.repo {
    repo = "firecracker";
    rev = "2532d50d9afb8ff2e9084f3345d263ab457c88fb";
  };

  cargoVendorConfig = fetchCrates "${src}/Cargo.lock";

  buildInputs = [ libfdt ];

  # TODO why is this necessary?
  extraCargoConfig = {
    target.${hostPlatform.config}.fdt = {
      rustc-link-search = [ "native=${libfdt}/lib" ];
    };
  };

  postPatch = ''
    rm -r .cargo
  '';

}
