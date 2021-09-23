{ lib, hostPlatform
, icecapSrc
, buildRustPackage
, fetchCrates
, libfdt

, mkShell
, stdenv, buildPackages
, cargo, rustc, git, cacert, python3
, crateUtils, nixToToml
}:

let
  # TODO why is this necessary?
  config = crateUtils.clobber [
    {
      target.${hostPlatform.config}.fdt = {
        rustc-link-search = [ "native=${libfdt}/lib" ];
      };
    }
  ];

in
buildRustPackage rec {
  pname = "firecracker";
  version = "0.25.0";
  src = icecapSrc.repo {
    repo = "firecracker";
    rev = "2532d50d9afb8ff2e9084f3345d263ab457c88fb";
  };

  buildInputs = [ libfdt ];

  extraCargoConfig = (fetchCrates "${src}/Cargo.lock").config // config;

  postPatch = ''
    rm -r .cargo
  '';

  dontFixup = true;

  # env

  passthru.env =
    let
      cargoConfig = nixToToml (crateUtils.clobber [
        crateUtils.baseCargoConfig
        config
      ]);
    in
      mkShell (crateUtils.baseEnv // {

        depsBuildBuild = [ buildPackages.stdenv.cc ];
        nativeBuildInputs = [ rustc cargo git cacert python3 ];
        buildInputs = [ libfdt ];

        shellHook = ''
          c() {
            rm -f .cargo/config
            ln -s ${cargoConfig} .cargo/config
          }
          b() {
            cargo build \
              --target ${stdenv.hostPlatform.config} \
              -j $NIX_BUILD_CORES
          }
          d() {
            cargo doc \
              --target ${stdenv.hostPlatform.config} \
              -j $NIX_BUILD_CORES
          }
          s() {
            (cd target/${stdenv.hostPlatform.config}/doc && python3 -m http.server)
          }
        '';
      });

}
