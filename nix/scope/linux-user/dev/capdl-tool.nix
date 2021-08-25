{ stdenv, haskellPackages
, repos
, which, libxml2, graphviz
, lib
, mkIceCapSrc
}:

haskellPackages.mkDerivation {
  pname = "capdl-tool";
  version = "1.0.0.1";

  # TODO make configurable

  src = repos.rel.capdl "capDL-tool";
  # src = repos.forceLocal.rel.capdl "capDL-tool";

  doCheck = false;

  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = with haskellPackages; [
    array base base-compat containers filepath MissingH mtl parsec
    pretty split
    yaml
    aeson
  ];
  license = lib.licenses.bsd2;

  testToolDepends = map (x: x.nativeDrv) [ which libxml2 graphviz ];
  checkPhase = ''
    PATH=dist/build/parse-capDL:$PATH make tests
  '';

  buildTools = [
    haskellPackages.cabal-install
  ];
}

#   shellHook = ''
#     builddir=${toString ../../../tmp/dist}
#     c() {
#       cabal configure --builddir=$builddir
#     }
#     b() {
#       cabal build --builddir=$builddir
#     }
#   '';
