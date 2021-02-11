{ stdenv, fetchgit }:

stdenv.mkDerivation rec {
  name = "dtc-${version}";
  version = "1.5.0";

  src = fetchgit {
    url = "https://git.kernel.org/pub/scm/utils/dtc/dtc.git";
    rev = "refs/tags/v${version}";
    sha256 = "10y5pbkcj5gkijcgnlvrh6q2prpnvsgihb9asz3zfp66mcjwzsy3";
  };

  prePatch = ''
    cd libfdt
  '';

  configurePhase = ''
    ln -s ${./Makefile} Makefile
  '';

  makeFlags = [
    "PREFIX=$(out)"
  ];

}
