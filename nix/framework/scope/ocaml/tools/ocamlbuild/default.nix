{ stdenv, buildPlatform, hostPlatform, fetchFromGitHub, ocaml }:

# assert buildPlatform == hostPlatform;

stdenv.mkDerivation rec {
  name = "ocamlbuild-${version}";
  version = "0.14.0";
  src = fetchFromGitHub {
    owner = "ocaml";
    repo = "ocamlbuild";
    rev = version;
    sha256 = "1hb5mcdz4wv7sh1pj7dq9q4fgz5h3zg7frpiya6s8zd3ypwzq0kh";
  };

  patches = [
    ./where.patch
  ];

  nativeBuildInputs = [ ocaml ];

  configurePhase = ''
    make -f configure.make \
      "OCAMLBUILD_PREFIX=$out" \
      "OCAMLBUILD_BINDIR=$out/bin" \
      "OCAMLBUILD_MANDIR=$out/share/man" \
      "OCAMLBUILD_LIBDIR=$out/lib"
  '';

}
