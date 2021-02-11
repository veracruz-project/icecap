{ stdenv, buildPlatform, hostPlatform
, fetchFromGitHub
, ocamlView, ocamlfind, ocamlbuild, opam-file-format, applyFindlibConf
}:

stdenv.mkDerivation rec {
  name = assert buildPlatform == hostPlatform; "opaline-${version}";
  version =  "0.3.2";
  src = fetchFromGitHub {
    owner = "jaapb";
    repo = "opaline";
    rev = "v${version}";
    sha256 = "1aj1fdqymq3pnr39h47hn3kxk5v9pnwx0jap1z2jzh78x970z21m";
  };

  nativeBuildInputs = [ ocamlView ocamlfind ocamlbuild  ];

  preConfigure = applyFindlibConf {
    buildInputs = [ opam-file-format ocamlfind ];
  };

  preInstall = ''
    mkdir -p $out/bin
  '';

  installFlags = [ "PREFIX=$(out)" ];

}
