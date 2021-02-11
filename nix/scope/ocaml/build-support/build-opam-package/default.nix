{ stdenv, lib, buildPlatform, hostPlatform, buildPackages
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
, createDestdir ? true
, setToolchain ? false
, stdenv_ ? stdenv
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
        in go nativeBuildInputsOCaml ++ propagatedNativeBuildInputsOCaml;
    in
      let go = lib.concatMap (x: [ x ] ++ go (x.propagatedBuildInputsOCaml or []));
      in go topNatives;

  findlibConf = applyFindlibConf {
    buildInputs = lib.unique allBuildInputsOCaml;
    nativeBuildInputs = lib.unique allNativeBuildInputsOCaml;
  };

in
stdenv_.mkDerivation ({

  configurePhase = ''
    runHook preConfigure
    ${findlibConf}
    runHook postConfigure
  '';

  installPhase = ''
    runHook preInstall
    ${lib.optionalString createDestdir ''
      mkdir -p $(ocamlfind printconf destdir)
    ''}
    opaline -prefix $out${lib.optionalString (buildPlatform != hostPlatform) "/mycross-sysroot"}
    runHook postInstall
  '';

} // lib.optionalAttrs (setToolchain && buildPlatform != hostPlatform) {
  OCAMLFIND_TOOLCHAIN = "mycross";
} // builtins.removeAttrs args [ "stdenv_" ] // {

  name = "ocaml-${ocaml.version}-${pname}-${version}";

  depsBuildBuild = [ ocamlBuildBuild buildPackages.stdenv.cc ] ++ (args.depsBuildBuild or []);
  nativeBuildInputs = [ ocamlfind ocamlbuild opaline ] ++ (args.nativeBuildInputs or []);

  passthru = {
    inherit propagatedBuildInputsOCaml;
    inherit propagatedNativeBuildInputsOCaml;
  } // (args.passthru or {});

})
