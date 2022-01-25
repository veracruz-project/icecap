{ stdenv, python3 }:

crate:

stdenv.mkDerivation {

  pname = crate.crateMeta.name;
  inherit (crate.crateMeta) version;
  src = crate;

  nativeBuildInputs = [ python3 ];

  phases = [ "unpackPhase" "installPhase" ];

  postUnpack = ''
    mv $sourceRoot $out
    sourceRoot=$out
  '';

  installPhase = ''
    find . -type f -exec sha256sum {} \; | python3 ${./unpack-helper.py} ${crate.crateMeta.sha256}
  '';

  passthru = {
    inherit (crate) crateMeta;
  };

}
