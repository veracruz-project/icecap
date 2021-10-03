{ lib, stdenv
, haskellPackages
, seL4EcosystemRepos
}:

haskellPackages.mkDerivation {
  pname = "capdl-tool";
  version = "1.0.0.1";

  src = seL4EcosystemRepos.capdl.extendInnerSuffix "capDL-tool";

  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = with haskellPackages; [
    aeson array base base-compat bytestring containers filepath lens
    MissingH mtl parsec pretty regex-compat split text unix yaml
  ];

  doCheck = false;

  license = lib.licenses.bsd2;

}

  # shellHook = ''
  #   c() {
  #     cabal configure --builddir=$builddir
  #   }
  #   b() {
  #     cabal build --builddir=$builddir
  #   }
  # '';
