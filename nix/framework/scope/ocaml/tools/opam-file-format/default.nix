{ stdenv, buildPlatform, hostPlatform, fetchFromGitHub, ocaml }:

assert buildPlatform == hostPlatform;

stdenv.mkDerivation rec {
  name = "ocaml-${ocaml.version}-opam-file-format-${version}";
  version = "2.0.0";
  src = fetchFromGitHub {
    owner = "ocaml";
    repo = "opam-file-format";
    rev = "${version}";
    sha256 = "0fqb99asnair0043hhc8r158d6krv5nzvymd0xwycr5y72yrp0hv";
  };

  nativeBuildInputs = [ ocaml ];

  installFlags = [ "LIBDIR=$(out)/lib" ];

}
