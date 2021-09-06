{ lib, stdenv
, haskellPackages
, which, libxml2, graphviz
, seL4EcosystemRepos
}:

haskellPackages.mkDerivation {
  pname = "capdl-tool";
  version = "1.0.0.1";

  src = seL4EcosystemRepos.capdl.extendInnerSuffix "capDL-tool";

  doCheck = false;

  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = with haskellPackages; [
    aeson array base base-compat bytestring containers filepath lens
    MissingH mtl parsec pretty regex-compat split text unix yaml
  ];
  license = lib.licenses.bsd2;

  testToolDepends = [ which libxml2 graphviz ];
  checkPhase = ''
    PATH=dist/build/parse-capDL:$PATH make tests
  '';

  buildTools = [
    haskellPackages.cabal-install
  ];

  shellHook = ''
    builddir=${toString ../../../tmp/dist}
    c() {
      cabal configure --builddir=$builddir
    }
    b() {
      cabal build --builddir=$builddir
    }
  '';

}
