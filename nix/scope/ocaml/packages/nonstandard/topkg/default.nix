{ buildOpamPackage, fetchurl, ocamlfind, ocamlPackages, buildPackagesOCaml }:

buildOpamPackage rec {
  pname = "topkg";
  version = "1.0.0";
  src = fetchurl {
    url = "http://erratique.ch/software/${pname}/releases/${pname}-${version}.tbz";
    sha256 = "1df61vw6v5bg2mys045682ggv058yqkqb67w7r2gz85crs04d5fw";
  };

  propagatedBuildInputsOCaml = with ocamlPackages; [ result ];
  propagatedNativeBuildInputsOCaml = with buildPackagesOCaml; [ findlib result ];

  postPatch = ''
    sed -i 's|#use "topfind"|#use "${buildPackagesOCaml.findlib}/lib/topfind"|' pkg/pkg.ml
    sed -i 's|requires = "bytes result"|requires = "result"|' pkg/META
  '';

  buildPhase = ''
    ocaml pkg/pkg.ml build
  '';

}
