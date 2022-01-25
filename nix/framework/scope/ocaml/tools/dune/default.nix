{ stdenv, hostPlatform, buildPlatform
, fetchFromGitHub
, ocaml, ocamlView, ocamlfind, opaline, applyFindlibConf
}:

stdenv.mkDerivation rec {
  pname = assert hostPlatform == buildPlatform; "dune";
  # version = "1.9.2";
  # src = fetchurl {
  #   url = "https://github.com/ocaml/dune/releases/download/${version}/dune-${version}.tbz";
  #   sha256 = "0l27d13wh3i1450kgxnhr6r977sgby1dqwsfc8cqd9mqic1mr9f2";
  # };
  version = "HEAD";
  src = fetchFromGitHub {
    owner = "ocaml";
    repo = pname;
    rev = "d328f334e3f55287b1c374715b664b9766b21673";
    sha256 = "1awm36icgl080fdp004vcsx26bmlax6jvv3p2qmrsb83w55xvvmj";
  };

  depsBuildBuild = [ ocaml ];
  nativeBuildInputs = [ ocamlfind opaline ];

  dontAddPrefix = true;
  HACK_BOOT = "1";

  patches = [
    ./future-syntax-cross.patch
  ];

  preConfigure = applyFindlibConf {};

  buildFlags = [ "release" ];

  installPhase = ''
    opaline -prefix $out -libdir $(ocamlfind printconf destdir)
    cp $(ocamlfind printconf destdir)/dune/future-syntax.exe $out/bin/future-syntax
  '';

}
