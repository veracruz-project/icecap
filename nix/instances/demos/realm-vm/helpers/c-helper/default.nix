{ stdenv }:

stdenv.mkDerivation {
  name = "c-helper";
  src = ./src;
  buildPhase = ''
    $CC main.c -o c-helper
  '';
  installPhase = ''
    install -D -t $out/bin c-helper
  '';
}
