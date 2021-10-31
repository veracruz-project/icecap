{ lib, mkShell, buildPackages
, rustc, cargo
, nixToToml, crateUtils, rustTargetName, globalCrates
, libsel4, libs, icecapPlat
, stdenv, icecapSrc, fetchCrates
}:

let

  lock = src + "/Cargo.lock";

  cargoConfig = nixToToml (crateUtils.clobber [
    crateUtils.baseCargoConfig
    (fetchCrates lock).config
    {
      target.${rustTargetName}.rustflags = [
        "--cfg=icecap_plat=\"${icecapPlat}\""
      ];
    }
  ]);

  flags = lib.concatStringsSep " " (lib.mapAttrsToList (k: _: "-p ${k}") globalCrates._icecapBins);

  src = (icecapSrc.relativeSplit "rust").store;

in stdenv.mkDerivation (crateUtils.baseEnv // {
  name = "test";

  phases = [ "configurePhase" "buildPhase" ];

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ cargo rustc ];
  buildInputs = [
    libsel4 libs.icecap-autoconf libs.icecap-runtime libs.icecap-utils
  ];

  LIBCLANG_PATH = "${lib.getLib buildPackages.llvmPackages.libclang}/lib";
  BINDGEN_EXTRA_CLANG_ARGS = [
    "-I${libsel4}/include"
    "-I${libs.icecap-autoconf}/include"
  ];

  configurePhase = ''
    mkdir .cargo
    ln -s ${cargoConfig} .cargo/config
  '';

  buildPhase = ''
    cargo build \
      --frozen \
      --target-dir target \
      --release \
      --target ${rustTargetName} \
      --manifest-path ${src}/Cargo.toml \
      ${flags} --out-dir $out -Z unstable-options
  '';

})
