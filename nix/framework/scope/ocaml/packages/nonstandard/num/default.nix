{ stdenv, lib, buildPlatform, hostPlatform, fetchFromGitHub, fetchpatch, ocaml, ocamlfind, applyFindlibConf }:

stdenv.mkDerivation rec {
  name = "ocaml-${ocaml.version}-num-${version}";
  version = "1.1";
  src = fetchFromGitHub {
    owner = "ocaml";
    repo = "num";
    rev = "v${version}";
    sha256 = "0a4mhxgs5hi81d227aygjx35696314swas0vzy3ig809jb7zq4h0";
  };

  patches = [
    (fetchpatch {
      url = "https://github.com/ocaml/num/commit/6d4c6d476c061298e6385e8a0864f083194b9307.patch";
      sha256 = "18zlvb5n327q8y3c52js5dvyy29ssld1l53jqng8m9w1k24ypi0b";
    })
  ];

  nativeBuildInputs = [ ocaml ocamlfind ];

  OCAMLFIND_TOOLCHAIN = "mycross";

  preConfigure = applyFindlibConf {};

  preInstall = ''
    mkdir -p $(ocamlfind printconf destdir)
  '';

}
