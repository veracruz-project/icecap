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

  src = (icecapSrc.relativeSplit "rust").store;

in stdenv.mkDerivation (crateUtils.baseEnv // {
  name = "test";

  phases = [ "configurePhase" "buildPhase" ];

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ cargo rustc ];
  buildInputs = [ libsel4 libs.icecap-runtime ];

  LIBCLANG_PATH = "${lib.getLib buildPackages.llvmPackages.libclang}/lib";
  BINDGEN_EXTRA_CLANG_ARGS = [
    "-I${libsel4}/include"
  ];

  configurePhase = ''
    mkdir .cargo
    ln -s ${cargoConfig} .cargo/config
  '';

  buildPhase = ''
    # cargo build \
    #   -Z unstable-options \
    #   --frozen \
    #   --target-dir target \
    #   --manifest-path ${src}/Cargo.toml \
    #   --out-dir $out/build \
    #   --target ${rustTargetName} \
    #   --release \
    #   $(awk '{print "-p" $$0}' < ${src}/support/crates-for-seL4.txt)

    CARGO_TARGET_AARCH64_ICECAP_RUSTDOCFLAGS="--cfg=icecap_plat=\"${icecapPlat}\"" \
      cargo doc \
        --frozen \
        --target-dir target \
        --manifest-path ${src}/Cargo.toml \
        --target ${rustTargetName} \
        $(awk '{print "-p" $$0}' < ${src}/support/crates-for-seL4.txt)
    
    mkdir -p $out/doc
    cp -r target/doc $out/doc/build
    cp -r target/${rustTargetName}/doc $out/doc/target
  '';

  passthru.adHocPath = "${rustTargetName}/${icecapPlat}";
})
