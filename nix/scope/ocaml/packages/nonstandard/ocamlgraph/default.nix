{ stdenv, lib, buildPlatform, hostPlatform
, fetchurl
, ocaml, ocamlbuild, ocamlfind, applyFindlibConf
}:

stdenv.mkDerivation rec {
  pname = "ocamlgraph";
  version = "1.8.8";
  src = fetchurl {
    url = "http://ocamlgraph.lri.fr/download/${pname}-${version}.tar.gz";
    sha256 = "0m9g16wrrr86gw4fz2fazrh8nkqms0n863w7ndcvrmyafgxvxsnr";
  };

  nativeBuildInputs = [ ocaml ocamlfind ];

  configurePhase = ''
    ${applyFindlibConf {}}
    ./configure
  '';
    # ${lib.optionalString (buildPlatform != hostPlatform) "export OCAMLFIND_TOOLCHAIN=mycross"}

  buildPhase = ''
    make OCAMLFIND=ocamlfind
  '';

  installPhase = ''
    mkdir -p $(ocamlfind printconf destdir)
    make install-findlib OCAMLFIND=ocamlfind
  '';

  noCross = true;

}
