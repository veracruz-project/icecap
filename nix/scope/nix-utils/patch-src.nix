{ stdenv }:

args:

stdenv.mkDerivation ({
  phases = [ "unpackPhase" "patchPhase" "installPhase" ];

  installPhase = ''
    here=$(pwd)
    cd $NIX_BUILD_TOP
    mv $here $out
  '';
} // args)
