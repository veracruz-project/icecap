{ stdenv, fetchFromGitHub, ocaml, ocamlfind, ocamlbuild, buildPackages, applyFindlibConf
, ocamlBuildBuild
}:

stdenv.mkDerivation rec {
  name = "ocaml-${ocaml.version}-seq-${version}";
  version = "0.1";
  src = fetchFromGitHub {
    owner = "c-cube";
    repo = "seq";
    rev = version;
    sha256 = "1cjpsc7q76yfgq9iyvswxgic4kfq2vcqdlmxjdjgd4lx87zvcwrv";
  };

  depsBuildBuild = [ ocamlBuildBuild buildPackages.stdenv.cc ];
  nativeBuildInputs = [ ocamlfind ocamlbuild ];

  OCAMLFIND_TOOLCHAIN = "mycross";

  postPatch = ''
    sed -i 's,ocamlbuild,ocamlbuild -use-ocamlfind,' Makefile
  '';

  preConfigure = applyFindlibConf {};

  preInstall = ''
    mkdir -p $(ocamlfind printconf destdir)
  '';

}
