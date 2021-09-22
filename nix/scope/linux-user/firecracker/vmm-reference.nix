{ lib, hostPlatform
, icecapSrc
, buildRustPackage
, fetchCrates
, libfdt
, mkShell, cargo, rustc, git, cacert, stdenv, buildPackages, crateUtils, nixToToml, python3
}:

let
  # TODO why is this necessary?
  fdtConfig = {
    target.${hostPlatform.config}.fdt = {
      rustc-link-search = [ "native=${libfdt}/lib" ];
    };
  };

in
buildRustPackage rec {
  pname = "vmm-reference";
  version = "0.1.0";
  src = builtins.fetchGit {
    url = "https://github.com/rust-vmm/vmm-reference";
    ref = "main";
    rev = "98b0f85d78886b430b0e7e457ad3932355c7da52";
  };

  buildInputs = [ libfdt ];

  extraCargoConfig = (fetchCrates "${src}/Cargo.lock").config // fdtConfig;

  postPatch = ''
    rm -r .cargo
  '';

  passthru.env =
    let
      cargoConfig = nixToToml (crateUtils.clobber [
        crateUtils.baseCargoConfig
        fdtConfig
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
