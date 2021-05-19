{ stdenv, lib, buildPackages, buildPlatform, hostPlatform
, cargo, rustc
, nixToToml, crateUtils, rustTargets
}:

{ cargoVendorConfig ? null # TODO remove
, release ? true
, extraCargoConfig ? {}
, ...
} @ args:

let

  cargoConfig = crateUtils.clobber [
    crateUtils.baseCargoConfig
    (lib.optionalAttrs (cargoVendorConfig != null) cargoVendorConfig.config)
    extraCargoConfig
  ];

in stdenv.mkDerivation (crateUtils.baseEnv // {

  depsBuildBuild = [ buildPackages.stdenv.cc ] ++ (args.depsBuildBuild or []);
  nativeBuildInputs = [ cargo ] ++ (args.nativeBuildInputs or []);

  NIX_HACK_CARGO_CONFIG = nixToToml cargoConfig;

  # TODO Is --offline necessary? Does it change the build in undesirable ways?
  buildPhase = ''
    runHook preBuild
    cargo build --offline --frozen \
      ${lib.optionalString (release) "--release"} \
      --target ${stdenv.hostPlatform.config} \
      -j $NIX_BUILD_CORES
    runHook postBuild
  '';

  # TODO cargoBuildFlags
  checkPhase = ''
    runHook preCheck
    cargo test --offline --frozen \
      -j $NIX_BUILD_CORES 
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    lib_re='.*\.\(so.[0-9.]+\|so\|a\|dylib\)'
    find target/${hostPlatform.config}/${if release then "release" else "debug"} -maxdepth 1 -type f -executable -not -regex "$lib_re" | xargs -r install -D -t $out/bin
    find target/${hostPlatform.config}/${if release then "release" else "debug"} -maxdepth 1                          -regex "$lib_re" | xargs -r install -D -t $out/lib
    runHook postInstall
  '';

} // builtins.removeAttrs args [
  "depsBuildBuild" "nativeBuildInputs"
])
