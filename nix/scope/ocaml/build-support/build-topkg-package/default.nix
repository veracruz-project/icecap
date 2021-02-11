{ stdenv, lib, buildPlatform, hostPlatform, buildPackages, buildPackagesOCaml
, fetchurl, ocaml, ocamlfind, ocamlbuild, opaline
, applyFindlibConf
, ocamlView
, ocamlBuildBuild
}:

{ pname, version
, buildInputsOCaml ? []
, nativeBuildInputsOCaml ? []
, propagatedBuildInputsOCaml ? []
, propagatedNativeBuildInputsOCaml ? []
, buildFlags ? []
, ...
} @ args:

let
  allBuildInputsOCaml =
    let go = lib.concatMap (x: [ x ] ++ go (x.propagatedBuildInputsOCaml or []));
    in go (buildInputsOCaml ++ propagatedBuildInputsOCaml);
  allNativeBuildInputsOCaml =
    let
      topNatives =
        let go = lib.concatMap (x: [ x ] ++ go (x.propagatedBuildInputsOCaml or []));
        in go (nativeBuildInputsOCaml ++ propagatedNativeBuildInputsOCaml ++ [ buildPackagesOCaml.topkg ]);
    in
      let go = lib.concatMap (x: [ x ] ++ go (x.propagatedBuildInputsOCaml or []));
      in go topNatives;

  findlibConf = applyFindlibConf {
    buildInputs = lib.unique allBuildInputsOCaml;
    nativeBuildInputs = lib.unique allNativeBuildInputsOCaml;
  };

in
stdenv.mkDerivation ({

  configurePhase = ''
    runHook preConfigure
    sed -i 's|#use "topfind"|#use "${buildPackagesOCaml.findlib}/lib/topfind"|' pkg/pkg.ml
    ${findlibConf}
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    ocaml pkg/pkg.ml build ${lib.concatStringsSep " " buildFlags}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    opaline -prefix $out${lib.optionalString (buildPlatform != hostPlatform) "/mycross-sysroot"}
    runHook postInstall
  '';

} // lib.optionalAttrs (buildPlatform != hostPlatform) {
  TOPKG_CONF_TOOLCHAIN = "mycross";
} // args // {

  name = "ocaml-${ocaml.version}-${pname}-${version}";

  depsBuildBuild = [ ocamlBuildBuild buildPackages.stdenv.cc ] ++ (args.depsBuildBuild or []);
  nativeBuildInputs = [ ocamlfind ocamlbuild opaline ] ++ (args.nativeBuildInputs or []);

  passthru = {
    inherit propagatedBuildInputsOCaml;
    inherit propagatedNativeBuildInputsOCaml;
  } // (args.passthru or {});

})
