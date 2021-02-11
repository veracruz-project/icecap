{ stdenv, lib, buildPlatform, hostPlatform, targetPlatform
, fetchurl, fetchpatch, m4
, ocaml, ocamlbuild
}:

let
  rel = "${lib.optionalString (buildPlatform != hostPlatform) "mycross-sysroot/"}lib";
in
stdenv.mkDerivation rec {
  pname = "ocamlfind";
  version = "1.8.0";
  src = fetchurl {
    url = "http://download.camlcity.org/download/findlib-${version}.tar.gz";
    sha256 = "1b97zqjdriqd2ikgh4rmqajgxwdwn013riji5j53y3xvcmnpsyrb";
  };

  outputs = [ "out" "dummies" ];

  nativeBuildInputs = [ m4 ocaml ocamlbuild ];

  dontAddPrefix = true;
  configurePlatforms = [];

  patches = [
    ./install_topfind.patch
  ];

  postPatch = lib.optionalString (buildPlatform != hostPlatform) ''
    sed -i 's,tools/extract_args/extract_args -o,ocamlrun tools/extract_args/extract_args -o,' configure
  '';

  configurePhase = ''
    ./configure \
      -bindir $out/bin \
      -mandir $out/share/man \
      -sitelib $out/${rel} \
      -config $NIX_BUILD_TOP/findlib.conf
  '';

  buildFlags = [ "all" "opt" ];

  postInstall = ''
    mkdir -p $dummies/${rel}
    mv $out/${rel}/* $dummies/${rel}
    mv $dummies/${rel}/{findlib,topfind} $out/${rel}/
  '';

}
