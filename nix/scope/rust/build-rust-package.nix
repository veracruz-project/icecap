{ stdenv, lib, buildPackages, buildPlatform, hostPlatform
, cargo, rustc
, nixToToml, crateUtils, rustTargets

# TODO unnecissary
, cacert, git
}:

let
  stdenv_ = stdenv;
in

{ cargoBuildFlags ? []
, cargoVendorConfig ? null
, cargoVendorConfigRaw ? null
, cargoVendorDir ? null
, debug ? false # TODO release ? true
, doc ? false, cargoDocFlags ? []
, offline ? true
, stdenv ? stdenv_
, extraCargoConfig ? {}
, ...
} @ args:

assert cargoVendorConfig == null || cargoVendorDir == null;

let

  # TODO rename
  releaseDir = "target/${stdenv.hostPlatform.config}/${if debug then "debug" else "release"}";

  ccEnv = {
    "CC_${buildPlatform.config}" = "${buildPackages.stdenv.cc.targetPrefix}cc";
    "CXX_${buildPlatform.config}" = "${buildPackages.stdenv.cc.targetPrefix}c++";
  } // {
    "CC_${hostPlatform.config}" = "${stdenv.cc.targetPrefix}cc";
    "CXX_${hostPlatform.config}" = "${stdenv.cc.targetPrefix}c++";
  };

  cargoVendorDirConfig = {
    source.crates-io.replace-with = "vendored-sources";
    source.vendored-sources.directory = cargoVendorDir;
  };

  cargoConfig = crateUtils.clobber [
    # TODO HACK
    (lib.optionalAttrs (cargoVendorConfigRaw != null) (builtins.fromTOML (builtins.readFile cargoVendorConfigRaw)))
    (lib.optionalAttrs (cargoVendorConfig != null) cargoVendorConfig.config)
    (lib.optionalAttrs (cargoVendorDir != null) cargoVendorDirConfig)

    {
      target = {
        ${buildPlatform.config}.linker = "${buildPackages.stdenv.cc.targetPrefix}cc";
      } // {
        ${hostPlatform.config}.linker =
          if hostPlatform.isWasm
          then "${buildPackages.icecap.rustc}/lib/rustlib/${buildPlatform.config}/bin/rust-lld"
          else
            if hostPlatform.system == "aarch64-none"
            then "${stdenv.cc.targetPrefix}ld"
            else "${stdenv.cc.targetPrefix}cc";
          # NOTE if not useing rust-lld, then the following is necessary for WASM:
          #   linker = "wasm-ld";
          #   rustflags = [ "-C" "linker-flavor=wasm-ld" ];
      };
    }

    extraCargoConfig
  ];

in stdenv.mkDerivation ({

  depsBuildBuild = [ buildPackages.stdenv.cc ] ++ (args.depsBuildBuild or []);
  nativeBuildInputs = [ cargo rustc git cacert ] ++ (args.nativeBuildInputs or []);

  RUST_TARGET_PATH = rustTargets;

  configurePhase = ''
    runHook preConfigure
    mkdir -p .cargo
    ln -s ${nixToToml cargoConfig} .cargo/config
    runHook postConfigure
  '';

  # TODO Is --offline necessary? Does it change the build in undesirable ways?
  buildPhase = ''
    runHook preBuild
    cargo build -j $NIX_BUILD_CORES ${lib.optionalString offline "--offline --frozen"} \
      ${lib.optionalString (!debug) "--release"} \
      --target ${stdenv.hostPlatform.config} \
      ${lib.concatStringsSep " " cargoBuildFlags}
    ${lib.optionalString doc ''
      cargo doc -j $NIX_BUILD_CORES ${lib.optionalString offline "--offline --frozen"} \
        ${lib.optionalString (!debug) "--release"} \
        --target ${stdenv.hostPlatform.config} \
        ${lib.concatStringsSep " " cargoDocFlags}
    ''}
    runHook postBuild
  '';

  # TODO cargoBuildFlags
  checkPhase = ''
    runHook preCheck
    cargo test ${lib.optionalString offline "--offline --frozen"} \
      ${lib.concatStringsSep " " cargoBuildFlags}
    runHook postCheck
  '';

  # TODO --out-dir
  installPhase = ''
    runHook preInstall
    lib_re='.*\.\(so.[0-9.]+\|so\|a\|dylib\)'
    find ${releaseDir} -maxdepth 1 -type f -executable -not -regex "$lib_re" | xargs -r install -D -t $out/bin
    find ${releaseDir} -maxdepth 1                          -regex "$lib_re" | xargs -r install -D -t $out/lib
    runHook postInstall
  '';
    # lib_re='.*\.\(so.[0-9.]+\|so\|a\|dylib\|rlib\)'

} // ccEnv // builtins.removeAttrs args [ "depsBuildBuild" "nativeBuildInputs" "extraCargoConfig" ])
