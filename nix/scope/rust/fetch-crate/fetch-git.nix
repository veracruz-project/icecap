{ stdenv, python3 }:

{ name, version, url, rev } @ args:

stdenv.mkDerivation {

  pname = name;
  inherit version;

  src = builtins.fetchGit {
    inherit url rev;
  };

  nativeBuildInputs = [ python3 ];

  postUnpack = ''
    mv $sourceRoot $out
    sourceRoot=$out
    rm -r $out/fuzz $out/.gitignore
  '';

  buildPhase = ''
    find . -type f -exec sha256sum {} \; | python3 ${./unpack-helper.py}
  '';

  dontInstall = true;
  dontFixup = true;

  passthru.crateMeta = args // {
    source = "git";
  };

}
