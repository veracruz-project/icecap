{ stdenv, lib, buildPlatform, hostPlatform, buildPackages, fetchFromGitHub, ocaml, ocamlfind, applyFindlibConf }:

stdenv.mkDerivation (rec {
  name = "ocaml-${ocaml.version}-ppx_tools-${version}";
  version = "5.1+4.06.0";
  src = fetchFromGitHub {
    owner = "ocaml-ppx";
    repo = "ppx_tools";
    rev = version;
    sha256 = "1ww4cspdpgjjsgiv71s0im5yjkr3544x96wsq1vpdacq7dr7zwiw";
  };

  patches = [
    ./use-ocamlfind.patch
  ];

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [ ocamlfind ];

  preConfigure = applyFindlibConf {};

  preInstall = ''
    mkdir -p $(ocamlfind printconf destdir)
  '';

} // lib.optionalAttrs (buildPlatform != hostPlatform) {

  buildPhase = ''
    make ast_lifter.ml dumpast ppx_metaquot rewriter
    export OCAMLFIND_TOOLCHAIN=mycross
    make all
  '';

})
