{ lib, stdenv, buildPackages, hostPlatform
, cargo, rustc
, nixToToml, crateUtils
}:

{ release ? true
, extraCargoConfig ? {}
, ...
} @ args:

let

  cargoConfig = nixToToml (crateUtils.clobber [
    crateUtils.baseCargoConfig
    extraCargoConfig
  ]);

in stdenv.mkDerivation (crateUtils.baseEnv // {

  depsBuildBuild = [ buildPackages.stdenv.cc ] ++ (args.depsBuildBuild or []);
  nativeBuildInputs = [ cargo rustc ] ++ (args.nativeBuildInputs or []);

  configurePhase = ''
    runHook preConfigure

    mkdir -p .cargo
    ln -s ${cargoConfig} .cargo/config

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    cargo build --offline --frozen \
      ${lib.optionalString (release) "--release"} \
      --target ${stdenv.hostPlatform.config} \
      -j $NIX_BUILD_CORES

    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck

    cargo test --offline --frozen \
      -j $NIX_BUILD_CORES

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    lib_re='.*\.\(so.[0-9.]+\|so\|a\|dylib\)'
    find target/${hostPlatform.config}/${if release then "release" else "debug"} -maxdepth 1 \
      -regex "$lib_re" \
      | xargs -r install -D -t $out/lib
    find target/${hostPlatform.config}/${if release then "release" else "debug"} -maxdepth 1 \
      -type f -executable -not -regex "$lib_re" \
      | xargs -r install -D -t $out/bin

    runHook postInstall
  '';

} // builtins.removeAttrs args [
  "depsBuildBuild" "nativeBuildInputs" "extraCargoConfig"
])
