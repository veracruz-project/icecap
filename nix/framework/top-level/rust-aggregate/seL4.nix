{ lib, mkShell, buildPackages
, rustc, cargo
, nixToToml, crateUtils, rustTargetName, globalCrates
, libsel4, userC, icecapPlat
, stdenv, icecapSrc, fetchCrates
}:

{ build ? false, release ? false, doc ? false, docDeps ? false, docAll ? false }:

let

  lock = src + "/Cargo.lock";

  cargoConfig = nixToToml (crateUtils.clobber [
    crateUtils.baseCargoConfig
    crateUtils.denyWarningsCargoConfig # NOTE this may become infeasible for dependencies
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
  buildInputs = [ libsel4 userC.nonRootLibs.icecap-runtime ];

  LIBCLANG_PATH = "${lib.getLib buildPackages.llvmPackages.libclang}/lib";
  BINDGEN_EXTRA_CLANG_ARGS = [
    "-I${libsel4}/include"
  ];

  configurePhase = ''
    mkdir .cargo
    ln -s ${cargoConfig} .cargo/config
  '';

  buildPhase = ''
    package_args=$(awk '{print "-p" $$0}' < ${src}/support/crates-for-seL4.txt)
    package_args_fewer_docs=$(comm -1 -2 ${src}/support/crates-for-seL4.txt ${src}/support/crates-for-docs.txt | awk '{print "-p" $$0}')

  '' + lib.optionalString build ''
    cargo build \
      -Z unstable-options \
      --frozen \
      --target-dir target \
      --manifest-path ${src}/Cargo.toml \
      --out-dir $out/bin \
      --target ${rustTargetName} \
      ${lib.optionalString release "--release"} \
      $package_args

  '' + lib.optionalString doc ''
    CARGO_TARGET_AARCH64_ICECAP_RUSTDOCFLAGS="--cfg=icecap_plat=\"${icecapPlat}\" -Z unstable-options --enable-index-page" \
      cargo doc \
        --frozen \
        --target-dir target \
        --manifest-path ${src}/Cargo.toml \
        --target ${rustTargetName} \
        ${lib.optionalString (!docDeps) "--no-deps"} \
        ${if docAll then "$package_args" else "$package_args_fewer_docs"}

    # HACK
    mkdir -p target/doc

    mkdir -p $out/doc
    cp -r target/doc $out/doc/build
    cp -r target/${rustTargetName}/doc $out/doc/host
  '';

  passthru.worldPath = "${rustTargetName}/${icecapPlat}";
})
