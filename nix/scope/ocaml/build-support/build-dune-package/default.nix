{ stdenv, lib, buildPlatform, hostPlatform, buildPackages
, fetchurl, ocaml, ocamlfind, dune, opaline
, applyFindlibConf
, ocamlView
, ocamlBuildBuild
}:

{ pname, version
, buildInputsOCaml ? []
, nativeBuildInputsOCaml ? []
, propagatedBuildInputsOCaml ? []
, propagatedNativeBuildInputsOCaml ? []
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
        in go (nativeBuildInputsOCaml ++ propagatedNativeBuildInputsOCaml);
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

  buildPhase = ''
    runHook preBuild
    dune build ${lib.optionalString (buildPlatform != hostPlatform) "-x mycross"} -p ${pname}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    opaline -prefix $out
    runHook postInstall
  '';

} // builtins.removeAttrs args [ "stdenv_" ] // {

  name = "ocaml-${ocaml.version}-${pname}-${version}";

  depsBuildBuild = [ ocamlBuildBuild buildPackages.stdenv.cc ] ++ (args.depsBuildBuild or []);
  nativeBuildInputs = [ dune ocamlfind opaline ] ++ (args.nativeBuildInputs or []);

  passthru = {
    inherit propagatedBuildInputsOCaml;
    inherit propagatedNativeBuildInputsOCaml;
  } // (args.passthru or {});

})
